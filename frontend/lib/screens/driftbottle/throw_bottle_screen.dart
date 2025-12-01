import 'package:flutter/material.dart';
import 'widgets/bottle_card_scaffold.dart';
import '../../services/drift_bottle_service.dart';

/// Screen for throwing (creating) a new drift bottle
class ThrowBottleScreen extends StatefulWidget {
  final String userId;

  const ThrowBottleScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<ThrowBottleScreen> createState() => _ThrowBottleScreenState();
}

class _ThrowBottleScreenState extends State<ThrowBottleScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _throwBottle() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write a message before throwing the bottle'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await DriftBottleService.throwBottle(
        userId: widget.userId,
        message: message,
      );

      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your bottle has been thrown into the ocean! 🌊'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to throw bottle: $e'),
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

  @override
  Widget build(BuildContext context) {
    return BottleCardScaffold(
      cardContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hint text at top
          Text(
            'Say hello, share kind words, or express your deepest stories anonymously. No judgement!',
            style: TextStyle(
              fontFamily: 'Urbanist',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          // Divider
          Container(
            height: 1,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          // Text input area
          Expanded(
            child: TextField(
              controller: _messageController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                hintText: 'Write your message here...',
                hintStyle: TextStyle(
                  fontFamily: 'Urbanist',
                  color: Colors.grey,
                ),
                border: InputBorder.none,
              ),
              style: const TextStyle(
                fontFamily: 'Urbanist',
                fontSize: 16,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
      bottomButtons: SizedBox(
        width: 200,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _throwBottle,
          style: BottleButtonStyles.primaryButtonStyle(),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Done',
                  style: BottleButtonStyles.buttonTextStyle,
                ),
        ),
      ),
    );
  }
}
