@echo off
cd /d "%~dp0"

if not exist ".venv\Scripts\python.exe" (
  echo Python virtual environment was not found.
  echo Run: python -m venv .venv
  exit /b 1
)

".venv\Scripts\python.exe" main.py
