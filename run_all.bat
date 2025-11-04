@echo off
echo ==========================================
echo Launching AI Mental Health Companion App
echo ==========================================

REM ---- Start FastAPI backend in new terminal ----
echo Starting FastAPI backend...
start cmd /k "cd /d %~dp0backend && call venv\Scripts\activate && uvicorn app.main:app --reload --host 0.0.0.0 --port 8000"

REM ---- Start Flutter frontend in new terminal ----
echo Starting Flutter frontend...
start cmd /k "cd /d %~dp0frontend && flutter run"

echo ==========================================
echo Both backend and frontend have been started!
echo ==========================================
pause
