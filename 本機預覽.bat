@echo off
chcp 65001 >nul
cd /d "%~dp0"
echo ============================================
echo   本機預覽伺服器啟動中...
echo   瀏覽器將自動開啟 http://localhost:8000
echo   預覽結束後，關閉這個黑色視窗即可。
echo ============================================
start "" "http://localhost:8000"
python -m http.server 8000
