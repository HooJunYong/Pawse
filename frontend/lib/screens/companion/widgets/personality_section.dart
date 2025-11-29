import 'package:flutter/material.dart';
import '../../../models/personality_model.dart';

/// Personality section widget for selecting or creating personality
class PersonalitySection extends StatelessWidget {
  final List<Personality> personalities;
  final Personality? selectedPersonality;
  final bool isCustomPersonality;
  final bool isLoading;
  final Function(Personality?) onPersonalitySelected;
  final VoidCallback onCustomSelected;
  final Color cardColor;
  final Color orangeColor;

  const PersonalitySection({
    super.key,
    required this.personalities,
    required this.selectedPersonality,
    required this.isCustomPersonality,
    required this.isLoading,
    required this.onPersonalitySelected,
    required this.onCustomSelected,
    this.cardColor = const Color(0xFFFEEDE7),
    this.orangeColor = const Color(0xFFED7E1C),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personality',
            style: TextStyle(
              fontFamily: 'Urbanist',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      // Personality options from database
                      ...personalities.map((personality) {
                        final isSelected = selectedPersonality?.personalityId ==
                            personality.personalityId;
                        return _buildPersonalityChip(
                          personality.personalityName,
                          isSelected,
                          () => onPersonalitySelected(personality),
                        );
                      }),
                      // Custom option
                      _buildPersonalityChip(
                        'Custom',
                        isCustomPersonality,
                        onCustomSelected,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalityChip(
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? orangeColor : Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              )
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Urbanist',
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
