@echo off
setlocal

set "STARTUP_CMD=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\Clipboard Sync API.cmd"

if exist "%STARTUP_CMD%" (
  echo Startup launcher is installed:
  echo "%STARTUP_CMD%"
  type "%STARTUP_CMD%"
  exit /b 0
)

echo Startup launcher is not installed.
exit /b 1
