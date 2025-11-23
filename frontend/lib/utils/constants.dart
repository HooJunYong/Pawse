import 'package:flutter/material.dart';

/// Application-wide constants
class AppConstants {
  // Prevent instantiation
  AppConstants._();

  /// App name
  static const String appName = 'Pawse';

  /// API Endpoints
  static const String loginEndpoint = '/login';
  static const String signupEndpoint = '/signup';
  static const String profileEndpoint = '/profile';
  static const String changePasswordEndpoint = '/change-password';
  static const String forgotPasswordEndpoint = '/forgot-password';
  static const String verifyOtpEndpoint = '/verify-otp';
  static const String resetPasswordEndpoint = '/reset-password';
}

/// Application color palette
class AppColors {
  // Prevent instantiation
  AppColors._();

  /// Primary beige background color
  static const Color beige = Color(0xFFF7F4F2);

  /// Dark brown text/button color
  static const Color darkBrown = Color(0xFF422006);

  /// Orange accent color
  static const Color orange = Color(0xFFF97316);

  /// Light gray for borders
  static const Color lightGray = Color(0xFFE5E7EB);

  /// Gray for secondary text
  static const Color gray = Color(0xFF6B7280);

  /// White color
  static const Color white = Colors.white;

  /// Error red color
  static const Color error = Colors.red;

  /// Success green color
  static const Color success = Colors.green;
}

/// Text styles used throughout the app
class AppTextStyles {
  // Prevent instantiation
  AppTextStyles._();

  /// Font family
  static const String fontFamily = 'Nunito';

  /// Large title style
  static const TextStyle title = TextStyle(
    fontSize: 28,
    fontFamily: fontFamily,
    fontWeight: FontWeight.bold,
    color: AppColors.darkBrown,
  );

  /// Subtitle style
  static const TextStyle subtitle = TextStyle(
    fontSize: 14,
    fontFamily: fontFamily,
    color: AppColors.gray,
  );

  /// Body text style
  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontFamily: fontFamily,
    color: AppColors.darkBrown,
  );

  /// Button text style
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontFamily: fontFamily,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
  );

  /// Label text style
  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontFamily: fontFamily,
    fontWeight: FontWeight.w600,
    color: AppColors.darkBrown,
  );
}

/// Layout constants
class AppLayout {
  // Prevent instantiation
  AppLayout._();

  /// Standard border radius
  static const double borderRadius = 12.0;

  /// Button border radius
  static const double buttonBorderRadius = 8.0;

  /// Card border radius
  static const double cardBorderRadius = 16.0;

  /// Standard padding
  static const double padding = 16.0;

  /// Large padding
  static const double paddingLarge = 24.0;

  /// Small padding
  static const double paddingSmall = 8.0;

  /// Avatar size
  static const double avatarSize = 64.0;

  /// Avatar border width
  static const double avatarBorderWidth = 3.0;
}
