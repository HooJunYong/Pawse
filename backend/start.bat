@echo off
REM Quick Start Script for AI Chat Backend
echo ========================================
echo AI Chat Module Backend - Quick Start
echo ========================================
echo.

REM Check if virtual environment exists
if not exist "venv\" (
    echo Creating virtual environment...
    python -m venv venv
    echo.
)

REM Activate virtual environment
echo Activating virtual environment...
call venv\Scripts\activate.bat
echo.

REM Install dependencies
echo Installing dependencies...
pip install -r requirements.txt
echo.

REM Check if .env exists
if not exist ".env" (
    echo WARNING: .env file not found!
    echo Please create .env file with your configuration
    echo.
    pause
    exit /b 1
)

REM Seed database (optional)
echo.
set /p seed="Do you want to seed the database with sample data? (y/n): "
if /i "%seed%"=="y" (
    echo.
    echo Seeding database...
    python seed_data.py
    echo.
)

REM Start the server
echo.
echo Starting FastAPI server...
echo Server will be available at: http://localhost:8000
echo API Documentation: http://localhost:8000/docs
echo.
echo Press Ctrl+C to stop the server
echo.
python app/main.py
