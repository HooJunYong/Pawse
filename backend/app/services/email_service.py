import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import logging
from ..config import settings

logger = logging.getLogger(__name__)

def send_otp_email(to_email: str, otp_code: str) -> bool:
    """
    Send OTP verification code via Gmail SMTP
    
    Args:
        to_email: Recipient email address
        otp_code: 6-digit OTP code
        
    Returns:
        True if email sent successfully, False otherwise
    """
    try:
        # Create message
        msg = MIMEMultipart('alternative')
        msg['Subject'] = 'Your Pawse Verification Code'
        msg['From'] = f"{settings.SMTP_FROM_NAME} <{settings.SMTP_USER}>"
        msg['To'] = to_email

        # HTML email body with styled OTP
        html = f"""
        <html>
          <body style="font-family: Arial, sans-serif; padding: 20px; background-color: #f5f5f5;">
            <div style="max-width: 600px; margin: 0 auto; background-color: #ffffff; padding: 40px; border-radius: 12px; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
              <div style="text-align: center; margin-bottom: 30px;">
                <h1 style="color: #f97316; margin: 0; font-size: 28px;">🐾 Pawse</h1>
              </div>
              
              <h2 style="color: #422006; text-align: center; font-size: 24px; margin-bottom: 20px;">
                Verification Code
              </h2>
              
              <p style="font-size: 16px; color: #4b5563; line-height: 1.6; margin-bottom: 20px;">
                Hello,
              </p>
              
              <p style="font-size: 16px; color: #4b5563; line-height: 1.6; margin-bottom: 30px;">
                You requested a password reset for your Pawse account. Please use the verification code below:
              </p>
              
              <div style="background-color: #fed7aa; padding: 30px; text-align: center; margin: 30px 0; border-radius: 10px; border: 2px solid #f97316;">
                <p style="font-size: 14px; color: #6b7280; margin: 0 0 10px 0; text-transform: uppercase; letter-spacing: 1px;">
                  Your Code
                </p>
                <h1 style="color: #422006; font-size: 42px; letter-spacing: 12px; margin: 0; font-weight: bold;">
                  {otp_code}
                </h1>
              </div>
              
              <div style="background-color: #fef3c7; padding: 15px; border-radius: 8px; margin: 20px 0;">
                <p style="font-size: 14px; color: #92400e; margin: 0;">
                  ⏰ This code will expire in <strong>10 minutes</strong>.
                </p>
              </div>
              
              <p style="font-size: 14px; color: #6b7280; line-height: 1.6; margin-top: 30px;">
                If you didn't request this code, please ignore this email or contact support if you have concerns.
              </p>
              
              <hr style="border: none; border-top: 1px solid #e5e7eb; margin: 30px 0;">
              
              <p style="font-size: 12px; color: #9ca3af; text-align: center; margin: 0;">
                © 2024 Pawse Team. All rights reserved.
              </p>
            </div>
          </body>
        </html>
        """
        
        # Plain text fallback
        text = f"""
        Pawse Verification Code
        
        Hello,
        
        You requested a password reset for your Pawse account.
        
        Your verification code is: {otp_code}
        
        This code will expire in 10 minutes.
        
        If you didn't request this code, please ignore this email.
        
        © 2024 Pawse Team
        """
        
        # Attach both HTML and plain text versions
        msg.attach(MIMEText(text, 'plain'))
        msg.attach(MIMEText(html, 'html'))

        # Connect to Gmail SMTP server and send
        with smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT) as server:
            server.starttls()  # Enable TLS encryption
            server.login(settings.SMTP_USER, settings.SMTP_PASSWORD)
            server.send_message(msg)
        
        logger.info(f"OTP email sent successfully to {to_email}")
        return True
        
    except smtplib.SMTPAuthenticationError as e:
        logger.error(f"SMTP authentication failed: {str(e)}")
        logger.error("Please check your Gmail app password in .env file")
        return False
    except smtplib.SMTPException as e:
        logger.error(f"SMTP error sending OTP email to {to_email}: {str(e)}")
        return False
    except Exception as e:
        logger.error(f"Unexpected error sending OTP email to {to_email}: {str(e)}")
        return False
