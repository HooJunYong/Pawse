# Gmail SMTP Setup Instructions

## Step 1: Enable 2-Step Verification

1. Go to your Google Account: https://myaccount.google.com/
2. Click on **Security** in the left menu
3. Under "How you sign in to Google", click on **2-Step Verification**
4. Follow the prompts to enable it (if not already enabled)

## Step 2: Generate App Password

1. After enabling 2-Step Verification, go to: https://myaccount.google.com/apppasswords
   - Or search for "App passwords" in your Google Account settings
2. You may need to sign in again
3. Under "Select app", choose **Mail**
4. Under "Select device", choose **Other (Custom name)**
5. Type "Pawse Backend" or any name you prefer
6. Click **GENERATE**
7. Google will show you a 16-character password (like: `abcd efgh ijkl mnop`)
8. **Copy this password immediately** (you won't be able to see it again)

## Step 3: Update Your .env File

1. Open `backend/.env` file
2. Find the line: `SMTP_PASSWORD=your_16_character_app_password_here`
3. Replace `your_16_character_app_password_here` with your app password
4. **Remove all spaces** from the app password

Example:
```env
SMTP_PASSWORD=abcdefghijklmnop
```

## Step 4: Verify Email Account

Make sure the `SMTP_USER` in `.env` is correct:
```env
SMTP_USER=pawseteam@gmail.com
```

## Step 5: Test the Setup

1. Restart your FastAPI backend server
2. Try the forgot password flow in your app
3. Check the terminal logs for any SMTP errors
4. Check your email inbox for the OTP code

## Troubleshooting

### "SMTP authentication failed"
- Double-check the app password (no spaces, correct characters)
- Make sure 2-Step Verification is enabled
- Try generating a new app password

### "Connection refused" or "Connection timeout"
- Check your internet connection
- Some networks block SMTP ports (587, 465)
- Try using a different network or VPN

### Email not received
- Check spam/junk folder
- Verify the email address exists in your database
- Check backend logs for errors
- Gmail might have rate limits (try waiting a minute)

## Security Notes

⚠️ **NEVER commit your app password to Git!**
- The `.env` file should be in `.gitignore`
- Keep your app password private
- Regenerate if compromised

## Email Sending Limits

Gmail SMTP has sending limits:
- Free accounts: ~500 emails/day
- Google Workspace: ~2000 emails/day

For production with higher volume, consider:
- SendGrid
- AWS SES
- Mailgun
- Postmark
