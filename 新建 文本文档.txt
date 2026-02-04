@echo off
chcp 65001 >nul
echo ==========================================
echo       正在启动自动保存与发布程序...
echo ==========================================

:: 1. 先把源码保存到 GitHub (防止电脑坏了稿子丢了)
echo [1/2] 正在备份写作原稿...
git add .
git commit -m "Auto-save: %date% %time%"
git push

:: 2. 再把网页发布出去
echo.
echo [2/2] 正在构建并发布网页...
call mkdocs gh-deploy

echo.
echo ==========================================
echo          🎉 全部搞定！网页已更新。
echo ==========================================
echo.
pause