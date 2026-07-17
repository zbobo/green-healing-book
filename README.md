# 綠療樂齡手作坊｜電子成果冊

以 GitHub Pages 部署的靜態電子成果冊閱讀器。
Canva 負責排版，本網站負責閱讀。

## 技術

- HTML / CSS / Vanilla JavaScript（無框架、無套件）
- CSS Scroll Snap 左右翻頁（一次一頁）
- 原生 `<dialog>` 縮圖導覽
- IntersectionObserver 追蹤頁碼
- 網址 `#p=N` 記錄目前頁，可分享指定頁面

## 專案結構

```text
├── index.html
├── css/style.css
├── js/app.js
├── data/books.json   ← 成果冊資料
└── books/
    └── demo/         ← 每本成果冊一個資料夾
        ├── 1.webp
        ├── ...
        └── thumbs/   ← 縮圖導覽用的小圖（寬 300px）
```

## 新增 / 更換成果冊

1. 在 `books/` 下建立新資料夾，放入各頁圖片
   - 建議 WebP、寬度 1200 px、單張 100~300 KB
   - ffmpeg 轉檔：`ffmpeg -i 原圖.jpg -vf "scale=1200:-2" -c:v libwebp -quality 82 1.webp`
   - 縮圖：`ffmpeg -i 原圖.jpg -vf "scale=300:-2" -c:v libwebp -quality 72 thumbs/1.webp`
2. 修改 `data/books.json` 的 `title`、`pages` 與 `thumbs` 清單

不需要修改 HTML。

## 本機預覽

因為使用 `fetch` 載入 JSON，需用本機伺服器開啟（不能直接雙擊 index.html）：

```bash
python -m http.server 8000
# 打開 http://localhost:8000
```

## 部署到 GitHub Pages

1. 建立 GitHub repository（例如 `green-healing-book`）並推上這個資料夾
2. Repository → Settings → Pages → Deploy from a branch → `main` / root
3. 網址為 `https://<帳號>.github.io/green-healing-book/`

所有路徑皆為相對路徑，子路徑部署可直接使用。
