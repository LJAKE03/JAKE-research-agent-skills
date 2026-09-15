@echo off
chcp 65001 >nul
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\Set-ResearchModels.ps1" -Interactive
echo.
pause
