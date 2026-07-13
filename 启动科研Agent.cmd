@echo off
chcp 65001 >nul
setlocal EnableExtensions DisableDelayedExpansion

for %%I in ("%~dp0.") do set "REPOSITORY_ROOT=%%~fI"
set "LAUNCHER_SCRIPT=%REPOSITORY_ROOT%\scripts\Start-ResearchAgent.ps1"
set "SELF_TEST=0"
if /I "%~1"=="--self-test" set "SELF_TEST=1"

if not exist "%LAUNCHER_SCRIPT%" (
    echo 错误：未找到启动脚本：
    echo %LAUNCHER_SCRIPT%
    echo 请确认“启动科研Agent.cmd”仍位于正式仓库根目录。
    pause
    exit /b 1
)

if "%SELF_TEST%"=="1" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%LAUNCHER_SCRIPT%" -ValidateOnly -NoGui
) else (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%LAUNCHER_SCRIPT%"
)
set "LAUNCHER_EXIT_CODE=%ERRORLEVEL%"

if not "%LAUNCHER_EXIT_CODE%"=="0" (
    echo.
    echo 启动器异常结束，退出代码：%LAUNCHER_EXIT_CODE%
    if "%SELF_TEST%"=="0" pause
)
exit /b %LAUNCHER_EXIT_CODE%
