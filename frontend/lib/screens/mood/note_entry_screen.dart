import 'package:flutter/material.dart';
import '../../utils/helpers.dart';
import '../../screens/homepage_screen.dart';
import '../../services/mood_service.dart';
import 'dart:convert';


class NoteEntryScreen extends StatefulWidget {
  final String selectedMoodAsset;
  final String userId;
  
  const NoteEntryScreen({
      super.key, 
      required this.userId, 
      required this.selectedMoodAsset
    });

  @override
  State<NoteEntryScreen> createState() => _NoteEntryScreenState();
}

class _NoteEntryScreenState extends State<NoteEntryScreen> {  
  static const Color _backgroundColor = Color(0xFFF7F4F2);
  static const Color _saveButtonColor = Color(0xFF5D2D05);
  static const Color _textColor = Color(0xFF4F3422);

  bool _isSubmitting = false;
  
  // TextEditingController to capture the note input
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed
    _noteController.dispose();
    super.dispose();
  }

  /// Submit mood with note
  Future<void> _submitMoodWithNote() async {
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

      // Get the note text from the controller
      final String noteText = _noteController.text.trim();
      
      // Submit mood to backend with note (can be empty)
      final response = await MoodService.submitMood(
        userId: widget.userId,
        moodLevel: moodLevel,
        note: noteText.isEmpty ? null : noteText, // Only send note if not empty
        date: DateTime.now(),
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
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
      // SingleChildScrollView ensures the screen adjusts when the keyboard pops up
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 60), // Top spacing
                
                // Display the selected mood emoji
                SizedBox(
                  height: 80, 
                  width: 80,
                  child: Image.asset(
                    widget.selectedMoodAsset, // Use the passed mood asset
                    fit: BoxFit.contain,
                  ),
                ),
                
                const SizedBox(height: 30),

                // Text Input Card
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _noteController, // Connect the controller
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    style: const TextStyle(
                      color: _textColor,
                      fontSize: 16,
                      height: 1.5,
                    ),
                    cursorColor: _saveButtonColor,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(24.0),
                      hintText: "What's got you feeling this way\ntoday?",
                      hintStyle: TextStyle(
                        color: Colors.grey.withOpacity(0.6),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Save Button
                SizedBox(
                  width: 160,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitMoodWithNote, // Disable when submitting
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _saveButtonColor,
                      foregroundColor: Colors.white, // Text color
                      elevation: 4,
                      shadowColor: _saveButtonColor.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                      disabledBackgroundColor: Colors.grey[400], // Color when disabled
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            "Save",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}