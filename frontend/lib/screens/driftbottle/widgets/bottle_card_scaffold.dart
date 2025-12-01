import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A shared scaffold widget for all drift bottle screens
/// Provides consistent background, back button, and card layout
class BottleCardScaffold extends StatelessWidget {
  /// The content to display inside the white card
  final Widget cardContent;

  /// The buttons to display at the bottom of the screen
  final Widget bottomButtons;

  /// Whether to show the back button (default: true)
  final bool showBackButton;

  /// Optional callback for back button (defaults to Navigator.pop)
  final VoidCallback? onBackPressed;

  const BottleCardScaffold({
    Key? key,
    required this.cardContent,
    required this.bottomButtons,
    this.showBackButton = true,
    this.onBackPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ensure the status bar is transparent to show the background image
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // --- Background Image ---
          Positioned.fill(
            child: Image.asset(
              'assets/images/drift_bottle_bg.png',
              fit: BoxFit.cover,
            ),
          ),

          // --- Foreground Content ---
          SafeArea(
            child: Column(
              children: [
                // 1. Back Button
                if (showBackButton)
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, top: 16.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.black87,
                          size: 28,
                        ),
                        onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),

                // 2. White Card Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: cardContent,
                    ),
                  ),
                ),

                // 3. Bottom Buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 40.0),
                  child: bottomButtons,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Common button styles for drift bottle screens
class BottleButtonStyles {
  static const Color primaryButtonColor = Color(0xFF5D2D05);
  static const Color secondaryButtonColor = Color(0xFFFFE4D6);

  /// Primary brown button style
  static ButtonStyle primaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: primaryButtonColor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
    );
  }

  /// Secondary light button style (for "Pass it on")
  static ButtonStyle secondaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: secondaryButtonColor,
      foregroundColor: primaryButtonColor,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
    );
  }

  /// Text style for buttons
  static const TextStyle buttonTextStyle = TextStyle(
    fontFamily: 'Urbanist',
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );
}
