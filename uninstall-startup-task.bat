@echo off
setlocal

set "STARTUP_CMD=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\Clipboard Sync API.cmd"
set "RUN_VALUE=Clipboard Sync API"
set "TASK_NAME=Clipboard Sync API"

if exist "%STARTUP_CMD%" (
  del "%STARTUP_CMD%"
  echo Startup launcher removed:
  echo "%STARTUP_CMD%"
)

schtasks /Delete /TN "%TASK_NAME%" /F >nul 2>&1

if not errorlevel 1 (
  echo Scheduled task removed: %TASK_NAME%
)

reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "%RUN_VALUE%" /F >nul 2>&1

if not errorlevel 1 (
  echo Registry Run launcher removed: %RUN_VALUE%
)

if not exist "%STARTUP_CMD%" (
  exit /b 0
)

echo Startup launcher was not installed.
