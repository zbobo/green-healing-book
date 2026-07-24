@echo off
chcp 950 >nul
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0compress-images.ps1"
echo.
pause
