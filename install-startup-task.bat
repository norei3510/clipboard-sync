@echo off
setlocal

set "PROJECT_DIR=%~dp0"
set "STARTUP_DIR=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "STARTUP_CMD=%STARTUP_DIR%\Clipboard Sync API.cmd"

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
