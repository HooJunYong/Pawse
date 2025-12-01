import 'package:flutter/material.dart';
import 'widgets/bottle_card_scaffold.dart';
import 'reply_bottle_screen.dart';
import '../../services/drift_bottle_service.dart';

/// Screen for viewing a picked up drift bottle
class PickupBottleScreen extends StatefulWidget {
  final String userId;
  final String bottleId;
  final String message;
  final String? senderId;

  const PickupBottleScreen({
    Key? key,
    required this.userId,
    required this.bottleId,
    required this.message,
    this.senderId,
  }) : super(key: key);

  @override
  State<PickupBottleScreen> createState() => _PickupBottleScreenState();
}

class _PickupBottleScreenState extends State<PickupBottleScreen> {
  bool _isLoading = false;

  Future<void> _passBottle() async {
    setState(() => _isLoading = true);

    try {
      final success = await DriftBottleService.passBottle(
        userId: widget.userId,
        bottleId: widget.bottleId,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bottle passed on to another person ⭐'),
            backgroundColor: Colors.blue,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pass bottle: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToReply() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReplyBottleScreen(
          userId: widget.userId,
          bottleId: widget.bottleId,
          originalMessage: widget.message,
        ),
      ),
    ).then((result) {
      // If reply was successful, pop this screen too
      if (result == true && mounted) {
        Navigator.of(context).pop(true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BottleCardScaffold(
      cardContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "Just received" label
          const Text(
            'Just received',
            style: TextStyle(
              fontFamily: 'Urbanist',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE89B3C), // Orange color from design
            ),
          ),
          const SizedBox(height: 16),
          // Message content
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                widget.message,
                style: const TextStyle(
                  fontFamily: 'Urbanist',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomButtons: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reply button
          SizedBox(
            width: 200,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _navigateToReply,
              style: BottleButtonStyles.primaryButtonStyle(),
              child: const Text(
                'Reply',
                style: BottleButtonStyles.buttonTextStyle,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Pass it on button
          SizedBox(
            width: 200,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _passBottle,
              style: BottleButtonStyles.secondaryButtonStyle(),
              child: _isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: BottleButtonStyles.primaryButtonColor,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'Pass it on ',
                          style: BottleButtonStyles.buttonTextStyle,
                        ),
                        Text('⭐', style: TextStyle(fontSize: 18)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
