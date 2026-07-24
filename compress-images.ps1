# ==========================================================
# 電子成果冊 圖片壓縮工具
# 用法：把 Canva 匯出的圖片（1.jpg、2.jpg…數字命名）放進「原圖」
#       資料夾，然後雙擊「壓縮圖片.bat」。
# 會自動：轉 WebP（寬1200）＋產縮圖（寬300）＋更新 books.json
# ==========================================================

$ErrorActionPreference = 'Stop'
$root     = $PSScriptRoot
$bookId   = 'demo'                          # 目前只有一本；未來多本可改這裡
$srcDir   = Join-Path $root '原圖'
$outDir   = Join-Path $root "books\$bookId"
$thumbDir = Join-Path $outDir 'thumbs'
$jsonPath = Join-Path $root 'data\books.json'

# --- 檢查環境 ---
if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    Write-Host '找不到 ffmpeg，無法壓縮。' -ForegroundColor Red
    exit 1
}
if (-not (Test-Path $srcDir)) {
    New-Item -ItemType Directory $srcDir | Out-Null
    Write-Host '已建立「原圖」資料夾。請把 Canva 匯出的圖片放進去，再執行一次。' -ForegroundColor Yellow
    exit 0
}

# --- 讀取原圖（依數字排序）---
$files = Get-ChildItem $srcDir -File | Where-Object { $_.Extension -match '^\.(jpg|jpeg|png)$' }
$bad = $files | Where-Object { $_.BaseName -notmatch '^\d+$' }
if ($bad) {
    Write-Host ('檔名必須是純數字（例如 1.jpg），以下檔案不符：' + ($bad.Name -join '、')) -ForegroundColor Red
    exit 1
}
$files = $files | Sort-Object { [int]$_.BaseName }
if ($files.Count -eq 0) {
    Write-Host '「原圖」資料夾裡沒有圖片（支援 jpg / png）。' -ForegroundColor Yellow
    exit 0
}
Write-Host ("找到 {0} 張原圖，開始壓縮..." -f $files.Count)

# --- 清掉舊檔、重新產生 ---
New-Item -ItemType Directory -Force $outDir, $thumbDir | Out-Null
Remove-Item (Join-Path $outDir '*.webp')   -ErrorAction SilentlyContinue
Remove-Item (Join-Path $thumbDir '*.webp') -ErrorAction SilentlyContinue

# 桌面若被 OneDrive 同步，新檔案寫入瞬間可能被短暫鎖住，
# 造成 ffmpeg 偶發 "Invalid argument" 且沒有真的產生新檔。
# 這裡失敗會自動重試，並在最終確認檔案有更新，而非只看指令有沒有跑完。
function Convert-WithRetry($srcPath, $destPath, $scale, $quality) {
    $beforeTime = if (Test-Path $destPath) { (Get-Item $destPath).LastWriteTime } else { $null }
    for ($attempt = 1; $attempt -le 4; $attempt++) {
        Remove-Item $destPath -ErrorAction SilentlyContinue
        try {
            ffmpeg -y -loglevel error -i $srcPath -vf "scale=$($scale):-2" -c:v libwebp -quality $quality -compression_level 6 $destPath
        } catch {
            # ffmpeg 寫入檔案瞬間被鎖住時，PowerShell 會把它的錯誤訊息當成中止錯誤，
            # 這裡接住它，交給下面的重試機制處理，不要讓整個腳本停掉。
        }
        $ok = (Test-Path $destPath) -and ((Get-Item $destPath).Length -gt 0) -and ((Get-Item $destPath).LastWriteTime -ne $beforeTime)
        if ($ok) { return $true }
        Start-Sleep -Milliseconds 400
    }
    return $false
}

$failed = @()
foreach ($f in $files) {
    $n = $f.BaseName
    $okPage  = Convert-WithRetry $f.FullName (Join-Path $outDir "$n.webp")   1200 82
    $okThumb = Convert-WithRetry $f.FullName (Join-Path $thumbDir "$n.webp") 300  72
    if (-not $okPage -or -not $okThumb) {
        $failed += $n
        Write-Host ("  第 {0} 頁 失敗（重試 4 次仍無法寫入，可能被 OneDrive 鎖住）" -f $n) -ForegroundColor Red
    } else {
        Write-Host ("  第 {0} 頁 完成" -f $n)
    }
}

if ($failed.Count -gt 0) {
    Write-Host ''
    Write-Host ("以下頁面壓縮失敗，請暫停 OneDrive 同步後重新執行一次：{0}" -f ($failed -join '、')) -ForegroundColor Red
    exit 1
}

# --- 更新 books.json 的 pages / thumbs 清單 ---
$json = Get-Content $jsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
$json.books[0].pages  = @($files | ForEach-Object { "books/$bookId/$($_.BaseName).webp" })
$json.books[0].thumbs = @($files | ForEach-Object { "books/$bookId/thumbs/$($_.BaseName).webp" })
$jsonText = $json | ConvertTo-Json -Depth 5
[System.IO.File]::WriteAllText($jsonPath, $jsonText, [System.Text.UTF8Encoding]::new($false))  # 不加 BOM，避免部分瀏覽器解析失敗

# --- 結果 ---
$total = [math]::Round((Get-ChildItem (Join-Path $outDir '*.webp') | Measure-Object Length -Sum).Sum / 1MB, 1)
Write-Host ''
Write-Host ("完成！共 {0} 頁，頁面總大小 {1} MB，books.json 已更新。" -f $files.Count, $total) -ForegroundColor Green
Write-Host '接下來：雙擊「本機預覽.bat」檢查沒問題後，再上傳（git add . / commit / push）。'
