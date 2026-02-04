@echo off
chcp 65001 >nul
echo ==========================================
echo       正在启动自动保存与发布程序...
echo ==========================================

:: 1. 备份源码 (如果有冲突先尝试拉取)
echo [1/2] 正在备份写作原稿...
git pull origin main
git add .
git commit -m "Update: %date% %time%"
git push

:: 2. 强制发布网页 (修复 Error 128)
echo.
echo [2/2] 正在强制构建并发布网页...
call mkdocs gh-deploy --force

echo.
echo ==========================================
if %errorlevel% neq 0 (
    echo ❌ 发布失败！可能是网络问题。
    echo 请检查 VPN 是否开启，或者稍后再试。
) else (
    echo 🎉 全部搞定！网页已强制更新。
)
echo ==========================================
echo.
pause