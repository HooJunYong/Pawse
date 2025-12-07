import 'package:flutter/material.dart';
import '../../widgets/bottom_nav.dart';
import '../../services/reward_service.dart';
import 'my_reward_screen.dart';
import 'dart:convert';

class RewardScreen extends StatefulWidget {
  final String userId;

  const RewardScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<RewardScreen> createState() => _RewardScreenState();
}

class _RewardScreenState extends State<RewardScreen> {
  int _currentIndex = 3; // Rewards icon index

  // Define Colors
  final Color kBackgroundColor = const Color(0xFFF7F4F2);
  final Color kBrownColor = const Color(0xFF5D2D05);
  final Color kOrangeColor = const Color(0xFFFF8C42);

  // State variables
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPoints = 0;
  List<Map<String, dynamic>> _availableRewards = [];

  @override
  void initState() {
    super.initState();
    _loadRewardData();
  }

  Future<void> _loadRewardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load user points
      final points = await RewardService.getUserPoints(widget.userId);
      
      // Load available rewards
      final rewardsData = await RewardService.getAvailableRewards(widget.userId);

      setState(() {
        _currentPoints = points;
        _availableRewards = List<Map<String, dynamic>>.from(
          rewardsData?['available_rewards'] ?? []
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load rewards: $e';
      });
    }
  }

  void _navigateToMyReward() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MyRewardScreen(userId: widget.userId),
      ),
    );
  }

  void _showRewardDialog(Map<String, dynamic> reward) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Reward Image/Icon
                if (reward['image_path'] != null && reward['image_path'].isNotEmpty)
                  Image.asset(
                    'assets/images/${reward['image_path']}',
                    height: 100,
                    width: 100,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        reward['reward_type'] == 'voucher'
                            ? Icons.confirmation_number
                            : Icons.pets,
                        size: 100,
                        color: kOrangeColor,
                      );
                    },
                  )
                else
                  Icon(
                    reward['reward_type'] == 'voucher'
                        ? Icons.confirmation_number
                        : Icons.pets,
                    size: 100,
                    color: kOrangeColor,
                  ),
                const SizedBox(height: 20),
                
                // Reward Name
                Text(
                  reward['reward_name'] ?? 'Reward',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                
                // Reward Description
                Text(
                  reward['description'] ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                
                // Cost
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: kOrangeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.monetization_on,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${reward['cost']} Points',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: kBrownColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: kBrownColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: kBrownColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _redeemReward(reward),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kBrownColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Redeem',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
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
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Error Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 60,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Title
                const Text(
                  'Oops!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Message
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // OK Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kBrownColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: 60,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Title
                const Text(
                  'Success!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Message
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // OK Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Awesome!',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _redeemReward(Map<String, dynamic> reward) async {
    Navigator.pop(context); // Close reward details dialog
    
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final result = await RewardService.redeemReward(
        userId: widget.userId,
        rewardId: reward['reward_id'],
      );

      if (mounted) {
        Navigator.pop(context); // Close loading

        if (result != null && result['success'] == true) {
          // Show success dialog
          _showSuccessDialog(
            'You have successfully redeemed ${reward['reward_name']}! 🎉'
          );

          // Reload data
          _loadRewardData();
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        
        // Parse error message
        String errorMsg = e.toString();
        String displayMessage = "Looks like you don't have enough points to redeem this reward.";
        
        // Check for specific error types
        if (errorMsg.contains('Insufficient points')) {
          displayMessage = "Looks like you don't have enough points to redeem this reward.";
        } else if (errorMsg.contains('already been redeemed')) {
          displayMessage = "You have already redeemed this reward.";
        } else if (errorMsg.contains('not found') || errorMsg.contains('inactive')) {
          displayMessage = "This reward is no longer available.";
        } else {
          displayMessage = "Something went wrong. Please try again later.";
        }
        
        // Show error dialog
        _showErrorDialog(displayMessage);
      }
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
          'Rewards',
          style: TextStyle(
            color: kBrownColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Main Content
          SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return _isLoading
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
                                  onPressed: _loadRewardData,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight - 20,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Remove _buildHeader() since title is now in AppBar
                                  _buildPointsCard(),
                                  const SizedBox(height: 20),
                                  _buildMyRewardCard(),
                                  const SizedBox(height: 30),
                                  _buildRewardsGrid(),
                                ],
                              ),
                            ),
                          );
              },
            ),
          ),

          // Bottom Navigation Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BottomNavBar(
              userId: widget.userId,
              selectedIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFFFC107),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.monetization_on,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '$_currentPoints Points',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyRewardCard() {
    return InkWell(
      onTap: _navigateToMyReward,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.confirmation_number,
                color: Color(0xFF4CAF50),
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'My reward',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.black54,
              size: 32,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardsGrid() {
    if (_availableRewards.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: Text(
            'No rewards available',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: _availableRewards.length,
      itemBuilder: (context, index) {
        final reward = _availableRewards[index];
        return _buildRewardCard(reward);
      },
    );
  }

  Widget _buildRewardCard(Map<String, dynamic> reward) {
    final isVoucher = reward['reward_type'] == 'voucher';
    
    return InkWell(
      onTap: () => _showRewardDialog(reward),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Reward Image or Icon
              if (reward['image_path'] != null && reward['image_path'].isNotEmpty)
                Image.asset(
                  'assets/images/${reward['image_path']}',
                  height: 80,
                  width: 80,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      isVoucher ? Icons.confirmation_number : Icons.pets,
                      size: 80,
                      color: kOrangeColor,
                    );
                  },
                )
              else
                Icon(
                  isVoucher ? Icons.confirmation_number : Icons.pets,
                  size: 80,
                  color: isVoucher ? Colors.blue : kOrangeColor,
                ),
              const SizedBox(height: 12),
              
              // Reward Name
              Text(
                reward['reward_name'] ?? 'Reward',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              
              // Points
              Text(
                '${reward['cost']} pts',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
