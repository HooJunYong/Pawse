import 'dart:convert';

import 'package:flutter/material.dart';

import '../../screens/homepage_screen.dart';
import '../../services/mood_nudge_service.dart';
import '../../services/mood_service.dart';
import '../../utils/helpers.dart';
import 'note_entry_screen.dart';

class MoodEntryConfirmationScreen extends StatefulWidget {
  final String userId;
  final String selectedMoodAsset;
  
  const MoodEntryConfirmationScreen({
    super.key, 
    required this.userId, 
    required this.selectedMoodAsset
  });

  @override
  State<MoodEntryConfirmationScreen> createState() => _MoodEntryConfirmationScreenState();
}

class _MoodEntryConfirmationScreenState extends State<MoodEntryConfirmationScreen> {
  static const Color _backgroundColor = Color(0xFFF7F4F2);
  static const Color _mainTextColor = Color(0xFF4F3422);

  bool _isSubmitting = false;

  /// Submit mood without note (for "Maybe later" button)
  Future<void> _submitMoodWithoutNote() async {
    if (_isSubmitting) return;
    
    setState(() {
      _isSubmitting = true;
    });

    try {
      // Convert asset path to database value
      final String? moodLevel = MoodConstants.assetToDbValue[widget.selectedMoodAsset];
      
      if (moodLevel == null) {
        throw Exception('Invalid mood asset');
      }

      // Submit mood to backend
      final response = await MoodService.submitMood(
        userId: widget.userId,
        moodLevel: moodLevel,
        note: null,
        date: DateTime.now(),
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Schedule Intelligent Nudge
        final moodType = MoodNudgeService.getMoodTypeFromDbValue(moodLevel);
        if (moodType != null) {
          await MoodNudgeService().scheduleMoodNudge(moodType);
        }

        // Success - navigate to home
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => HomeScreen(userId: widget.userId)),
          (route) => false, // Remove all previous routes
        );
      } else {
        // Handle error response
        final errorData = json.decode(response.body);
        final errorMessage = errorData['detail'] ?? 'Failed to submit mood';
        
        Helpers.showErrorSnackbar(context, errorMessage);
      }
    } catch (e) {
      if (!mounted) return;
      Helpers.showErrorSnackbar(context, 'Error submitting mood: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Main Title Text
                const Text(
                  "Want to talk about\nit?",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _mainTextColor,
                    fontSize: 32,
                    height: 1.2,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Urbanist',
                  ),
                ),
                const SizedBox(height: 40),

                // Buttons Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // "Maybe later" Button
                    Expanded(
                      child: _buildRoundedButton(
                        text: "Maybe later",
                        onPressed: _isSubmitting ? null : _submitMoodWithoutNote,
                        isLoading: _isSubmitting,
                      ),
                    ),
                    const SizedBox(width: 20),
                    // "OK" Button
                    Expanded(
                      child: _buildRoundedButton(
                        text: "OK",
                        onPressed: _isSubmitting ? null : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                            builder: (context) => NoteEntryScreen(
                              selectedMoodAsset: widget.selectedMoodAsset,
                              userId: widget.userId,
                            ),
                          ),
                        );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper widget to build the specific rounded white buttons
  Widget _buildRoundedButton({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.3),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
        disabledBackgroundColor: Colors.grey[300],
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
              ),
            )
          : Text(
              text,
              style: const TextStyle(
                fontFamily: 'Urbanist',
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
    );
  }
}