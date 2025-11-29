import 'package:flutter/material.dart';

/// Voice tone selection widget
class VoiceToneSection extends StatelessWidget {
  final String? selectedVoiceTone;
  final List<String> voiceTones;
  final Function(String?) onChanged;

  const VoiceToneSection({
    super.key,
    required this.selectedVoiceTone,
    required this.voiceTones,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Voice tone',
            style: TextStyle(
              fontFamily: 'Urbanist',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedVoiceTone,
                hint: const Text(
                  'Select One',
                  style: TextStyle(
                    fontFamily: 'Urbanist',
                    color: Colors.grey,
                  ),
                ),
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down),
                items: voiceTones.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontFamily: 'Urbanist',
                      ),
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
