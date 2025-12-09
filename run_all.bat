@echo off
echo ==========================================
echo Launching AI Mental Health Companion App
echo ==========================================
echo.
echo IMPORTANT: For mobile device testing:
echo 1. Connect mobile device to SAME Wi-Fi as PC
echo 2. Backend will run at: http://192.168.1.113:8000
echo 3. Mobile device must be on Wi-Fi (USB alone won't work)
echo.
echo Alternative: Use 'adb reverse tcp:8000 tcp:8000' for USB-only
echo ==========================================
echo.

REM ---- Start FastAPI backend in new terminal ----
echo Starting FastAPI backend...
start cmd /k "cd /d %~dp0backend && call venv\Scripts\activate && uvicorn app.main:app --reload --host 0.0.0.0 --port 8000"

REM ---- Wait for backend to start ----
timeout /t 3 /nobreak >nul

REM ---- Setup ADB reverse port forwarding (optional, for USB-only connection) ----
echo.
echo Setting up ADB port forwarding for USB connection...
adb reverse tcp:8000 tcp:8000 2>nul
if %errorlevel% equ 0 (
    echo ADB reverse successful - USB connection will work
) else (
    echo ADB reverse failed - Make sure device is on Wi-Fi
)
echo.

REM ---- Start Flutter frontend in new terminal ----
echo Starting Flutter frontend...
start cmd /k "cd /d %~dp0frontend && flutter run"

echo ==========================================
echo Both backend and frontend have been started!
echo ==========================================
pause
