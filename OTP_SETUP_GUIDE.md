# OTP Email System Setup Guide

This guide will help you set up the OTP (One-Time Password) email system for the Pawse application on a new device.

## Prerequisites

- Python 3.11 or higher installed
- Git installed
- Gmail account for sending OTP emails

## Step 1: Clone the Repository

```bash
git clone https://github.com/HooJunYong/Pawse.git
cd Pawse
```

## Step 2: Set Up Backend Environment

### 2.1 Create Virtual Environment

```bash
cd backend
python -m venv venv
```

### 2.2 Activate Virtual Environment

**Windows (Command Prompt):**
```cmd
venv\Scripts\activate.bat
```

**Windows (PowerShell):**
```powershell
venv\Scripts\Activate.ps1
```

**Mac/Linux:**
```bash
source venv/bin/activate
```

### 2.3 Install Python Dependencies

```bash
pip install -r requirements.txt
```

### 2.4 Install Additional Required Package

```bash
pip install pytz
```

## Step 3: Configure Gmail App Password

### 3.1 Enable 2-Factor Authentication on Gmail

1. Go to [Google Account Security](https://myaccount.google.com/security)
2. Enable **2-Step Verification** if not already enabled
3. Follow the prompts to set it up

### 3.2 Generate App Password

1. Go to [Google App Passwords](https://myaccount.google.com/apppasswords)
2. Select **Mail** as the app
3. Select **Windows Computer** (or your device type)
4. Click **Generate**
5. **Copy the 16-character password** (e.g., `abcd efgh ijkl mnop`)
6. Save it securely - you'll need it in the next step

## Step 4: Configure Environment Variables

### 4.1 Create `.env` File

In the `backend` folder, create a file named `.env` (if it doesn't exist)

### 4.2 Add Configuration

Add the following lines to `.env`:

```env
# MongoDB Configuration
MONGODB_URL=mongodb://localhost:27017
DATABASE_NAME=pawse_db

# JWT Secret (generate a random string)
SECRET_KEY=your-secret-key-here

# SMTP Email Configuration
SMTP_USER=teampawse@gmail.com
SMTP_PASSWORD=your-16-char-app-password-here
```

**Important:**
- Replace `your-16-char-app-password-here` with the app password from Step 3.2
- Remove any spaces from the app password (e.g., `abcdefghijklmnop`)
- If using a different Gmail account, replace `teampawse@gmail.com` with your email

## Step 5: Verify Installation

### 5.1 Check Environment Setup

```bash
python check_env.py
```

This will verify:
- ✅ Virtual environment is activated
- ✅ All required packages are installed
- ✅ `.env` file exists and is configured
- ✅ MongoDB connection is working

### 5.2 Start Backend Server

```bash
cd backend
uvicorn app.main:app --reload
```

You should see:
```
INFO:     Uvicorn running on http://127.0.0.1:8000 (Press CTRL+C to quit)
```

## Step 6: Test OTP System

### 6.1 Test Forgot Password Flow

1. Open the Flutter app
2. Go to Login screen
3. Click **Forgot Password?**
4. Enter a registered email address
5. Click **Send OTP**
6. Check the email inbox for OTP code
7. Enter the 6-digit code
8. Set a new password

### 6.2 Expected Behavior

- ✅ OTP email arrives within 30 seconds
- ✅ OTP code is 6 digits
- ✅ OTP expires after 10 minutes
- ✅ Maximum 5 attempts per OTP

## Common Issues & Solutions

### Issue 1: "SMTP Authentication Failed"

**Solution:**
- Verify you're using an **App Password**, not your regular Gmail password
- Ensure 2-Factor Authentication is enabled on the Gmail account
- Check that the app password has no spaces
- Try generating a new app password

### Issue 2: "No module named 'pytz'"

**Solution:**
```bash
pip install pytz
```

### Issue 3: "OTP has expired" immediately

**Solution:**
- This is now fixed in the code
- Make sure you have the latest version from the repository
- Restart the backend server after pulling updates

### Issue 4: Email not received

**Solution:**
- Check spam/junk folder
- Verify SMTP_USER email is correct in `.env`
- Verify SMTP_PASSWORD app password is correct
- Check backend logs for error messages

### Issue 5: "ConnectionError: MongoDB connection failed"

**Solution:**
- Ensure MongoDB is installed and running
- Start MongoDB service:
  - **Windows:** Start MongoDB from Services
  - **Mac:** `brew services start mongodb-community`
  - **Linux:** `sudo systemctl start mongod`

## Required Files Checklist

Before running the application, ensure these files exist:

- ✅ `backend/.env` - Environment variables
- ✅ `backend/requirements.txt` - Python dependencies
- ✅ `backend/app/config/settings.py` - SMTP settings
- ✅ `backend/app/services/email_service.py` - Email sending logic
- ✅ `backend/app/services/otp_service.py` - OTP generation/verification
- ✅ `backend/venv/` - Virtual environment with pytz installed

## Dependencies Summary

### Python Packages (from requirements.txt)
- fastapi
- uvicorn
- pymongo
- python-jose[cryptography]
- passlib[bcrypt]
- python-multipart
- python-dotenv
- pydantic
- pydantic-settings
- **pytz** (must be installed separately)

### System Requirements
- Python 3.11+
- MongoDB 4.4+
- Git
- Gmail account with App Password

## Security Notes

⚠️ **Important Security Practices:**

1. **Never commit `.env` file to Git**
   - It's already in `.gitignore`
   - Contains sensitive credentials

2. **Keep App Password secure**
   - Don't share in chat/email
   - Regenerate if exposed

3. **Use strong SECRET_KEY**
   - Generate random 32+ character string
   - Different for each environment

4. **OTP Security Features**
   - 10-minute expiration
   - Maximum 5 attempts
   - Single-use only
   - Automatically deleted after use

## Contact

If you encounter issues not covered in this guide:
1. Check backend logs in terminal
2. Verify all configuration steps
3. Ensure latest code from repository

---

**Last Updated:** November 29, 2025  
**Repository:** https://github.com/HooJunYong/Pawse  
**Branch:** minyee
