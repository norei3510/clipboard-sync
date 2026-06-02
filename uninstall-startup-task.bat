@echo off
setlocal

set "STARTUP_CMD=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\Clipboard Sync API.cmd"

if exist "%STARTUP_CMD%" (
  del "%STARTUP_CMD%"
  echo Startup launcher removed:
  echo "%STARTUP_CMD%"
  exit /b 0
)

echo Startup launcher was not installed.
