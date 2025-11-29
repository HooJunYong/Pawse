import 'package:flutter/material.dart';

/// Success dialog widget for navigation after companion creation
class SuccessDialog extends StatelessWidget {
  final String companionName;
  final VoidCallback onChatPressed;
  final VoidCallback onHomePressed;

  const SuccessDialog({
    super.key,
    required this.companionName,
    required this.onChatPressed,
    required this.onHomePressed,
  });

  static Future<void> show({
    required BuildContext context,
    required String companionName,
    required VoidCallback onChatPressed,
    required VoidCallback onHomePressed,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SuccessDialog(
        companionName: companionName,
        onChatPressed: onChatPressed,
        onHomePressed: onHomePressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.check_circle,
                color: Color(0xFF4CAF50),
                size: 50,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            const Text(
              'Companion Created!',
              style: TextStyle(
                fontFamily: 'Urbanist',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5D2D05),
              ),
            ),
            const SizedBox(height: 12),

            // Message
            Text(
              '$companionName has been created successfully.\nWhere would you like to go?',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Urbanist',
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onHomePressed,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF5D2D05),
                      side: const BorderSide(color: Color(0xFF5D2D05)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Homepage',
                      style: TextStyle(
                        fontFamily: 'Urbanist',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onChatPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFED7E1C),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Chat',
                      style: TextStyle(
                        fontFamily: 'Urbanist',
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
