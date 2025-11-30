import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isMine;
  final DateTime timestamp;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = isMine
        ? const Color(0xFFFFD9B3)
        : Colors.white.withOpacity(0.85);
    final textColor = isMine ? const Color(0xFF3E2723) : const Color(0xFF5D4037);

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(18).copyWith(
            bottomRight: Radius.circular(isMine ? 4 : 18),
            bottomLeft: Radius.circular(isMine ? 18 : 4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: textColor,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _formatTime(timestamp),
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 11,
                color: const Color(0xFF8D6E63),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    final hours = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minutes = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hours:$minutes $period';
  }
}
