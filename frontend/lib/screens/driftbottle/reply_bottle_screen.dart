import 'package:flutter/material.dart';
import 'widgets/bottle_card_scaffold.dart';
import '../../services/drift_bottle_service.dart';

/// Screen for replying to a picked up drift bottle
class ReplyBottleScreen extends StatefulWidget {
  final String userId;
  final String bottleId;
  final String originalMessage;

  const ReplyBottleScreen({
    Key? key,
    required this.userId,
    required this.bottleId,
    required this.originalMessage,
  }) : super(key: key);

  @override
  State<ReplyBottleScreen> createState() => _ReplyBottleScreenState();
}

class _ReplyBottleScreenState extends State<ReplyBottleScreen> {
  final TextEditingController _replyController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _sendReply() async {
    final replyContent = _replyController.text.trim();
    if (replyContent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write a reply before sending'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await DriftBottleService.replyToBottle(
        userId: widget.userId,
        bottleId: widget.bottleId,
        replyContent: replyContent,
      );

      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your reply has been sent! 💌'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send reply: $e'),
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
          const SizedBox(height: 12),
          // Original message
          Text(
            widget.originalMessage,
            style: const TextStyle(
              fontFamily: 'Urbanist',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          // Divider
          Container(
            height: 1,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          // Reply hint text
          Text(
            'When replying, be supportive and understanding. Let\'s make this a kind and safe place for everyone.',
            style: TextStyle(
              fontFamily: 'Urbanist',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 1,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 12),
          // Reply text input
          Expanded(
            child: TextField(
              controller: _replyController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                hintText: 'Write your reply here...',
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
          onPressed: _isLoading ? null : _sendReply,
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
                  'Send Reply',
                  style: BottleButtonStyles.buttonTextStyle,
                ),
        ),
      ),
    );
  }
}
