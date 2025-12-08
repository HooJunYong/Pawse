import 'package:flutter/material.dart';
import '../services/activity_service.dart';

class RankBadge extends StatelessWidget {
  final String userId;
  final bool showLoading;

  const RankBadge({
    Key? key,
    required this.userId,
    this.showLoading = true,
  }) : super(key: key);

  Color _getRankColor(String rank) {
    final lowerRank = rank.toLowerCase();
    if (lowerRank.contains('silver')) {
      return const Color(0xFFC0C0C0);
    } else if (lowerRank.contains('gold')) {
      return const Color(0xFFFFD700);
    } else {
      return const Color(0xFFCD7F32); // Bronze
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: ActivityService.getUserRank(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return showLoading
              ? Container(
                  width: 60,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(20),
                  ),
                )
              : const SizedBox.shrink();
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          // Fallback to Bronze if error or no data
          return _buildBadge('Bronze');
        }

        final rankData = snapshot.data!;
        final rankName = rankData['rank_name'] ?? 'Bronze';

        return _buildBadge(rankName);
      },
    );
  }

  Widget _buildBadge(String rankName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _getRankColor(rankName),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        rankName,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}