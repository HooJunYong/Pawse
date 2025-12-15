import 'package:flutter/material.dart';
import 'controllers/my_reward_controller.dart';

class MyRewardScreen extends StatefulWidget {
  final String userId;

  const MyRewardScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<MyRewardScreen> createState() => _MyRewardScreenState();
}

class _MyRewardScreenState extends State<MyRewardScreen> {
  late MyRewardController _controller;
  
  final Color kBackgroundColor = const Color(0xFFF7F4F2);
  final Color kBrownColor = const Color(0xFF5D2D05);
  final Color kOrangeColor = const Color(0xFFFF8C42);

  @override
  void initState() {
    super.initState();
    _controller = MyRewardController(userId: widget.userId);
    _controller.addListener(_onControllerUpdate);
    _controller.loadInventory();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: kBrownColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Rewards',
          style: TextStyle(
            color: kBrownColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _controller.errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _controller.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _controller.loadInventory,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _controller.redeemedRewards.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 80,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No rewards redeemed yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Start redeeming rewards to see them here!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _controller.redeemedRewards.length,
                      itemBuilder: (context, index) {
                        final reward = _controller.redeemedRewards[index];
                        return _buildRewardItem(reward);
                      },
                    ),
    );
  }

  Widget _buildRewardItem(Map<String, dynamic> reward) {
    final isVoucher = reward['reward_type'] == 'voucher';
    final redeemedDate = DateTime.parse(reward['redeemed_date']);
    final formattedDate = '${redeemedDate.day}/${redeemedDate.month}/${redeemedDate.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Reward Icon/Image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isVoucher 
                  ? Colors.blue.withOpacity(0.1)
                  : kOrangeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: reward['image_path'] != null && reward['image_path'].isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/${reward['image_path']}',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          isVoucher ? Icons.confirmation_number : Icons.pets,
                          color: isVoucher ? Colors.blue : kOrangeColor,
                          size: 32,
                        );
                      },
                    ),
                  )
                : Icon(
                    isVoucher ? Icons.confirmation_number : Icons.pets,
                    color: isVoucher ? Colors.blue : kOrangeColor,
                    size: 32,
                  ),
          ),
          const SizedBox(width: 16),
          
          // Reward Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward['reward_name'] ?? 'Reward',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reward['reward_description'] ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Redeemed: $formattedDate',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Owned',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4CAF50),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
