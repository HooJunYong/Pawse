import 'package:flutter/material.dart';
import 'name_section.dart';

/// Custom personality card widget for creating a new personality
class CustomPersonalityCard extends StatelessWidget {
  final TextEditingController personalityNameController;
  final TextEditingController descriptionController;
  final Color cardColor;

  const CustomPersonalityCard({
    super.key,
    required this.personalityNameController,
    required this.descriptionController,
    this.cardColor = const Color(0xFFFEEDE7),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const FormLabel(text: 'Personality Name'),
            const SizedBox(height: 10),
            CustomTextField(
              controller: personalityNameController,
              hintText: 'Give your personality a name',
              fillColor: Colors.white,
            ),
            const SizedBox(height: 20),
            const FormLabel(text: 'Description'),
            const SizedBox(height: 10),
            CustomTextField(
              controller: descriptionController,
              hintText: 'Describe how you want your companion to be',
              maxLines: 4,
              fillColor: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
