import 'package:flutter/material.dart';
import '../../services/reward_service.dart';

class MyRewardScreen extends StatefulWidget {
  final String userId;

  const MyRewardScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<MyRewardScreen> createState() => _MyRewardScreenState();
}

class _MyRewardScreenState extends State<MyRewardScreen> {
  final Color kBackgroundColor = const Color(0xFFF7F4F2);
  final Color kBrownColor = const Color(0xFF5D2D05);
  final Color kOrangeColor = const Color(0xFFFF8C42);

  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _redeemedRewards = [];

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final inventoryData = await RewardService.getUserInventory(widget.userId);

      setState(() {
        _redeemedRewards = List<Map<String, dynamic>>.from(
          inventoryData?['inventory'] ?? []
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load inventory: $e';
      });
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _loadInventory,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _redeemedRewards.isEmpty
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
                      itemCount: _redeemedRewards.length,
                      itemBuilder: (context, index) {
                        final reward = _redeemedRewards[index];
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
