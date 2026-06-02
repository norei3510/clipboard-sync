@echo off
powershell -NoProfile -ExecutionPolicy Bypass -Command "$connections = Get-NetTCPConnection -LocalPort 8787 -State Listen -ErrorAction SilentlyContinue; if (-not $connections) { Write-Host 'Clipboard Sync API is not running.'; exit 0 }; $connections | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force }; Write-Host 'Clipboard Sync API stopped.'"
