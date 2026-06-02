Set-Location -Path $PSScriptRoot

if (-not (Test-Path -Path ".\.venv\Scripts\python.exe")) {
    Write-Error "Python virtual environment was not found. Run: python -m venv .venv"
    exit 1
}

.\.venv\Scripts\python.exe main.py
