import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../models/companion_model.dart';
import 'controllers/change_companion_controller.dart';

class ChangeCompanionScreen extends StatefulWidget {
  final String userId;
  final String currentCompanionId;

  const ChangeCompanionScreen({Key? key, required this.userId, required this.currentCompanionId})
    : super(key: key);

  @override
  State<ChangeCompanionScreen> createState() => _ChangeCompanionScreenState();
}

class _ChangeCompanionScreenState extends State<ChangeCompanionScreen> {
  late ChangeCompanionController _controller;

  // Colors from design
  final Color _bgColor = const Color(0xFFF7F4F2);
  final Color _btnBrown = const Color(0xFF5D3A1A);
  final Color _cardBg = Colors.white;
  final Color _textDark = const Color(0xFF1A1A1A);

  @override
  void initState() {
    super.initState();
    _controller = ChangeCompanionController();
    _controller.addListener(_onControllerUpdate);
    _controller.loadCompanions(widget.userId, widget.currentCompanionId);
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

  void _confirmSelection() {
    final selectedId = _controller.getSelectedCompanionId();
    if (selectedId != null) {
      Navigator.pop(context, selectedId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: _textDark, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Main scrollable content
            Expanded(
              child: _controller.isLoading
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
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => _controller.loadCompanions(
                              widget.userId,
                              widget.currentCompanionId,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),

                          // Current companion image at top
                          if (_controller.currentCompanion != null)
                            Transform.translate(
                              offset: const Offset(0, -50),
                              child: Center(
                                child: Image.asset(
                                  'assets/images/${_controller.currentCompanion!.image}',
                                  width: 180,
                                  height: 180,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(
                                      'assets/images/americonsh1.png',
                                      width: 180,
                                      height: 180,
                                      fit: BoxFit.contain,
                                    );
                                  },
                                ),
                              ),
                            ),

                          // "Choose one!" title
                          Text(
                            'Choose one!',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: _textDark,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Subtitle
                          Text(
                            'Choose how you want\nmy personality to be!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: _textDark,
                              height: 1.4,
                            ),
                          ),

                          const SizedBox(height: 30),

                          // List of companion cards
                          ..._controller.companions.map((companion) {
                            final isSelected =
                                _controller.selectedCompanion?.companionId ==
                                companion.companionId;
                            return _buildCompanionCard(companion, isSelected);
                          }).toList(),

                          const SizedBox(height: 20),
                          
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              'Cannot find a Companion that you like? Go ahead and create a new Companion at Profile --> Customize Your Companion!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: _textDark.withOpacity(0.6),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),

                          const SizedBox(height: 100), // Extra space for button
                        ],
                      ),
                    ),
            ),

            // Fixed Select button at bottom
            if (!_controller.isLoading && _controller.errorMessage == null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  color: _bgColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _controller.selectedCompanion != null
                        ? _confirmSelection
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _btnBrown,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _btnBrown.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 4,
                    ),
                    child: const Text(
                      'Select',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanionCard(Companion companion, bool isSelected) {
    return GestureDetector(
      onTap: () => _controller.selectCompanion(companion),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? _btnBrown : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Companion image in circle
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.black.withOpacity(0.1),
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/${companion.image}',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      'assets/images/americonsh1.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    );
                  },
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Companion info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Companion name
                  Text(
                    companion.companionName,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Companion description
                  Text(
                    companion.description,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: _textDark.withOpacity(0.8),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
