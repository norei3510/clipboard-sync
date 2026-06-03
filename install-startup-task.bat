@echo off
setlocal

set "PROJECT_DIR=%~dp0"
set "STARTUP_DIR=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "STARTUP_CMD=%STARTUP_DIR%\Clipboard Sync API.cmd"
set "STARTUP_VBS=%PROJECT_DIR%start-server-hidden.vbs"
set "RUN_VALUE=Clipboard Sync API"
set "TASK_NAME=Clipboard Sync API"

if not exist "%STARTUP_DIR%" (
  echo Startup folder was not found: "%STARTUP_DIR%"
  exit /b 1
)

(
  echo @echo off
  echo wscript.exe "%PROJECT_DIR%start-server-hidden.vbs"
) > "%STARTUP_CMD%"

if errorlevel 1 (
  echo Failed to install startup launcher.
  exit /b 1
)

echo Startup launcher installed:
echo "%STARTUP_CMD%"

reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "%RUN_VALUE%" /t REG_SZ /d "wscript.exe \"%STARTUP_VBS%\"" /f >nul 2>&1

if errorlevel 1 (
  echo Registry Run launcher was not installed. Startup folder launcher is still installed.
) else (
  echo Registry Run launcher installed: %RUN_VALUE%
)

schtasks /Create /TN "%TASK_NAME%" /TR "wscript.exe \"%STARTUP_VBS%\"" /SC ONLOGON /F >nul 2>&1

if errorlevel 1 (
  echo Scheduled task was not installed. Startup folder launcher is still installed.
  exit /b 0
)

echo Scheduled task installed: %TASK_NAME%
