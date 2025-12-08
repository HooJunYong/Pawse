import 'package:flutter/material.dart';
import '../../services/companion_service.dart';
import '../../models/companion_model.dart';
import '../../models/personality_model.dart';
import 'update_companion_screen.dart';

class ManageCompanionScreen extends StatefulWidget {
  final String userId;

  const ManageCompanionScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<ManageCompanionScreen> createState() => _ManageCompanionScreenState();
}

class _ManageCompanionScreenState extends State<ManageCompanionScreen> {
  final Color _bgColor = const Color(0xFFF7F4F2);
  final Color _cardColor = const Color(0xFFFEEDE7);
  final Color _titleColor = const Color(0xFF5D2D05);
  
  bool _isLoading = true;
  List<Companion> _companions = [];
  Map<String, String> _personalityNames = {};
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCompanions();
  }

  Future<void> _loadCompanions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final companions = await CompanionService.getUserCompanions(widget.userId);
      
      // Fetch personalities to get names
      final personalities = await CompanionService.getAvailablePersonalities(widget.userId);
      final personalityMap = {
        for (var p in personalities) p.personalityId: p.personalityName
      };

      setState(() {
        _companions = companions;
        _personalityNames = personalityMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToUpdate(Companion companion) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpdateCompanionScreen(
          userId: widget.userId,
          companion: companion,
        ),
      ),
    );

    // Reload companions if update was successful
    if (result == true) {
      _loadCompanions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Manage Companions',
          style: TextStyle(
            color: _titleColor,
            fontWeight: FontWeight.w200,
            fontFamily: 'Urbanist',
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load companions',
                        style: TextStyle(fontSize: 16, color: _titleColor),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadCompanions,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _companions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.pets_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No companions yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: _titleColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create your first companion to get started',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _companions.length,
                      itemBuilder: (context, index) {
                        final companion = _companions[index];
                        return _buildCompanionCard(companion);
                      },
                    ),
    );
  }

  Widget _buildCompanionCard(Companion companion) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToUpdate(companion),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Companion Image
                Container(
                  width: 60,
                  height: 60,
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
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/images/americonsh1.png',
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Companion Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        companion.companionName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _titleColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Personality Name
                      if (_personalityNames.containsKey(companion.personalityId)) ...[
                        Text(
                          'Personality: ${_personalityNames[companion.personalityId]}',
                          style: TextStyle(
                            fontSize: 12,
                            color: _titleColor.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      if (companion.voiceTone != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Voice: ${companion.voiceTone}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Arrow Icon
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
