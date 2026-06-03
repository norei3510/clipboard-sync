@echo off
setlocal

set "STARTUP_CMD=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\Clipboard Sync API.cmd"
set "RUN_VALUE=Clipboard Sync API"
set "TASK_NAME=Clipboard Sync API"
set "INSTALLED=0"

if exist "%STARTUP_CMD%" (
  echo Startup launcher is installed:
  echo "%STARTUP_CMD%"
  type "%STARTUP_CMD%"
  set "INSTALLED=1"
) else (
  echo Startup launcher is not installed.
)

reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "%RUN_VALUE%" >nul 2>&1

if errorlevel 1 (
  echo Registry Run launcher is not installed.
) else (
  echo Registry Run launcher is installed:
  reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "%RUN_VALUE%"
  set "INSTALLED=1"
)

schtasks /Query /TN "%TASK_NAME%" >nul 2>&1

if errorlevel 1 (
  echo Scheduled task is not installed.
  if "%INSTALLED%"=="1" exit /b 0
  exit /b 1
)

echo Scheduled task is installed:
schtasks /Query /TN "%TASK_NAME%" /FO LIST
set "INSTALLED=1"
exit /b 0
