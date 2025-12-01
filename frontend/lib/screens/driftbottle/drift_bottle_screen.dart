import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'throw_bottle_screen.dart';
import 'pickup_bottle_screen.dart';
import 'widgets/bottle_card_scaffold.dart';
import '../../services/drift_bottle_service.dart';

/// Main landing screen for the Drift Bottle feature
class DriftBottleScreen extends StatefulWidget {
  final String userId;

  const DriftBottleScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<DriftBottleScreen> createState() => _DriftBottleScreenState();
}

class _DriftBottleScreenState extends State<DriftBottleScreen> {
  bool _isPickingUp = false;

  Future<void> _pickupBottle() async {
    setState(() => _isPickingUp = true);

    try {
      final bottle = await DriftBottleService.pickupBottle(userId: widget.userId);

      if (bottle != null && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PickupBottleScreen(
              userId: widget.userId,
              bottleId: bottle['bottle_id'],
              message: bottle['message'],
              senderId: bottle['user_id'],
            ),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No bottles available right now. Try again later! 🌊'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick up bottle: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingUp = false);
      }
    }
  }

  void _navigateToThrow() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ThrowBottleScreen(userId: widget.userId),
      ),
    );
  }

  /// Show the thrown bottle history dialog
  void _showThrownHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => _ThrownHistoryDialog(userId: widget.userId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final buttonColor = BottleButtonStyles.primaryButtonColor;

    // Ensure the status bar is transparent to show the background image
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
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
                // 1. App Bar (Back Button + History Icon)
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 28),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.history_edu, color: Colors.black87, size: 28),
                        onPressed: _showThrownHistoryDialog,
                        tooltip: 'Thrown Bottle History',
                      ),
                    ],
                  ),
                ),

                // 2. Main Text Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: const [
                        SizedBox(height: 20),
                        Text(
                          'Drift & Heal',
                          style: TextStyle(
                            fontFamily: 'Urbanist',
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 24),
                        Text(
                          'A safe space where you can release your thoughts into the sea or discover messages from others. Share kind words, express your deepest stories anonymously with no judgement!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Urbanist',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 3. Bottom Buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 40.0),
                  child: Row(
                    children: [
                      // "Pick up bottle" Button
                      Expanded(
                        child: _buildBottleButton(
                          text: _isPickingUp ? 'Picking...' : 'Pick up bottle',
                          color: buttonColor,
                          fontFamily: 'Urbanist',
                          onPressed: _isPickingUp ? null : _pickupBottle,
                          isLoading: _isPickingUp,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // "Throw a bottle" Button
                      Expanded(
                        child: _buildBottleButton(
                          text: 'Throw a bottle',
                          color: buttonColor,
                          fontFamily: 'Urbanist',
                          onPressed: _navigateToThrow,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottleButton({
    required String text,
    required Color color,
    required String fontFamily,
    VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Text(
              text,
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}

/// Dialog to display thrown bottle history
class _ThrownHistoryDialog extends StatefulWidget {
  final String userId;

  const _ThrownHistoryDialog({required this.userId});

  @override
  State<_ThrownHistoryDialog> createState() => _ThrownHistoryDialogState();
}

class _ThrownHistoryDialogState extends State<_ThrownHistoryDialog> {
  List<Map<String, dynamic>> _bottles = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final bottles = await DriftBottleService.getThrownHistory(userId: widget.userId);
      
      // Sort bottles: available first, then completed, then expired
      // Within each status, sort by created_at descending
      bottles.sort((a, b) {
        final statusOrder = {'available': 0, 'picked_up': 1, 'completed': 2, 'expired': 3};
        final statusA = statusOrder[a['status']] ?? 4;
        final statusB = statusOrder[b['status']] ?? 4;
        
        if (statusA != statusB) {
          return statusA.compareTo(statusB);
        }
        
        // Same status, sort by date descending
        final dateA = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(1970);
        final dateB = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(1970);
        return dateB.compareTo(dateA);
      });

      if (mounted) {
        setState(() {
          _bottles = bottles;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _truncateMessage(String message, int wordLimit) {
    final words = message.split(' ');
    if (words.length <= wordLimit) {
      return message;
    }
    return '${words.take(wordLimit).join(' ')}...';
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return 'Unknown';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'picked_up':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'expired':
        return Colors.grey;
      default:
        return Colors.black87;
    }
  }

  void _showBottleDetailDialog(Map<String, dynamic> bottle) {
    showDialog(
      context: context,
      builder: (context) => _BottleDetailDialog(
        userId: widget.userId,
        bottle: bottle,
        onBottleEnded: () {
          // Refresh the list after ending a bottle
          _loadHistory();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Thrown Bottles',
                  style: TextStyle(
                    fontFamily: 'Urbanist',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            
            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Text(
                            'Failed to load history',
                            style: TextStyle(color: Colors.red[400]),
                          ),
                        )
                      : _bottles.isEmpty
                          ? const Center(
                              child: Text(
                                'No bottles thrown yet.\nStart by throwing your first bottle! 🍾',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Urbanist',
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: _bottles.length,
                              itemBuilder: (context, index) {
                                final bottle = _bottles[index];
                                final status = bottle['status'] ?? 'unknown';
                                
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () => _showBottleDetailDialog(bottle),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _truncateMessage(bottle['message'] ?? '', 5),
                                            style: const TextStyle(
                                              fontFamily: 'Urbanist',
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                _formatDate(bottle['created_at']),
                                                style: TextStyle(
                                                  fontFamily: 'Urbanist',
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: _getStatusColor(status).withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  status.toUpperCase(),
                                                  style: TextStyle(
                                                    fontFamily: 'Urbanist',
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: _getStatusColor(status),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog to display bottle details with option to end
class _BottleDetailDialog extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> bottle;
  final VoidCallback onBottleEnded;

  const _BottleDetailDialog({
    required this.userId,
    required this.bottle,
    required this.onBottleEnded,
  });

  @override
  State<_BottleDetailDialog> createState() => _BottleDetailDialogState();
}

class _BottleDetailDialogState extends State<_BottleDetailDialog> {
  bool _isEnding = false;
  bool _isLoadingDetails = true;
  Map<String, dynamic>? _bottleDetails;
  List<dynamic> _replies = [];

  @override
  void initState() {
    super.initState();
    _loadBottleDetails();
  }

  Future<void> _loadBottleDetails() async {
    try {
      final details = await DriftBottleService.getBottleDetail(
        bottleId: widget.bottle['bottle_id'],
      );

      if (mounted) {
        setState(() {
          _bottleDetails = details;
          _replies = details?['replies'] ?? [];
          _isLoadingDetails = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingDetails = false;
        });
      }
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy - hh:mm a').format(date);
    } catch (e) {
      return 'Unknown';
    }
  }

  String _formatReplyDate(String? dateStr) {
    if (dateStr == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return 'Unknown';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'picked_up':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'expired':
        return Colors.grey;
      default:
        return Colors.black87;
    }
  }

  Future<void> _showEndConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'End Bottle?',
          style: TextStyle(
            fontFamily: 'Urbanist',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Are you sure you want to end this bottle? You will stop receiving replies and the bottle will no longer be available for others to pick up.',
          style: TextStyle(
            fontFamily: 'Urbanist',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(fontFamily: 'Urbanist'),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'End Bottle',
              style: TextStyle(fontFamily: 'Urbanist', fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _endBottle();
    }
  }

  Future<void> _endBottle() async {
    setState(() => _isEnding = true);

    try {
      await DriftBottleService.endBottle(
        userId: widget.userId,
        bottleId: widget.bottle['bottle_id'],
      );

      if (mounted) {
        Navigator.of(context).pop(); // Close detail dialog
        widget.onBottleEnded(); // Refresh parent list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bottle ended successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to end bottle: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isEnding = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.bottle['status'] ?? 'unknown';
    final isAvailable = status.toLowerCase() == 'available';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Bottle Details',
                  style: TextStyle(
                    fontFamily: 'Urbanist',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            
            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Status
                    Row(
                      children: [
                        const Text(
                          'Status: ',
                          style: TextStyle(
                            fontFamily: 'Urbanist',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              fontFamily: 'Urbanist',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(status),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Date
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: Colors.black54),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(widget.bottle['created_at']),
                          style: TextStyle(
                            fontFamily: 'Urbanist',
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Message
                    const Text(
                      'Message:',
                      style: TextStyle(
                        fontFamily: 'Urbanist',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.bottle['message'] ?? 'No message',
                        style: const TextStyle(
                          fontFamily: 'Urbanist',
                          fontSize: 15,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Replies Section
                    Row(
                      children: [
                        const Icon(Icons.reply_all, size: 18, color: Colors.black54),
                        const SizedBox(width: 8),
                        Text(
                          'Replies (${_replies.length})',
                          style: const TextStyle(
                            fontFamily: 'Urbanist',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (_isLoadingDetails)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_replies.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Text(
                          'No replies yet',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Urbanist',
                            fontSize: 14,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    else
                      ...(_replies.map((reply) {
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFFE082)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                reply['reply_content'] ?? '',
                                style: const TextStyle(
                                  fontFamily: 'Urbanist',
                                  fontSize: 14,
                                  color: Colors.black87,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.access_time, size: 12, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatReplyDate(reply['reply_time']),
                                    style: TextStyle(
                                      fontFamily: 'Urbanist',
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList()),
                    
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // End button (only for available bottles)
            if (isAvailable)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isEnding ? null : _showEndConfirmation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isEnding
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'End Bottle',
                          style: TextStyle(
                            fontFamily: 'Urbanist',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}