import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../chat/chat_session_screen.dart';
import '../homepage_screen.dart';
import 'controllers/customize_companion_controller.dart';
import 'widgets/widgets.dart';

class CustomizeCompanionScreen extends StatefulWidget {
  final String? userId;
  const CustomizeCompanionScreen({super.key, this.userId});

  @override
  State<CustomizeCompanionScreen> createState() =>
      _CustomizeCompanionScreenState();
}

class _CustomizeCompanionScreenState extends State<CustomizeCompanionScreen> {
  // --- Colors ---
  final Color _bgColor = const Color(0xFFF7F4F2);
  final Color _orangeColor = const Color(0xFFED7E1C);
  final Color _cardColor = const Color(0xFFFEEDE7);
  final Color _saveBtnColor = const Color(0xFF5D2D05);

  // --- Page Controller ---
  late PageController _pageController;
  late CustomizeCompanionController _controller;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.45, initialPage: 1);
    _controller = CustomizeCompanionController(userId: widget.userId);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Handle save button press
  Future<void> _handleSave() async {
    final success = await _controller.saveCompanion();

    if (!mounted) return;

    if (success) {
      // Show success dialog
      SuccessDialog.show(
        context: context,
        companionName: _controller.createdCompanion?.companionName ?? 'Companion',
        onChatPressed: () {
          Navigator.of(context).pop(); // Close dialog
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => ChatSessionScreen(userId: widget.userId ?? ''),
            ),
          );
        },
        onHomePressed: () {
          Navigator.of(context).pop(); // Close dialog
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => HomeScreen(userId: widget.userId ?? ''),
            ),
          );
        },
      );
    } else {
      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_controller.errorMessage ?? 'Failed to create companion'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        backgroundColor: _bgColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Customize Companion',
            style: TextStyle(
              color: Color(0xFF5D2D05),
              fontWeight: FontWeight.w200,
              fontFamily: 'Urbanist',
              fontSize: 20,
            ),
          ),
          centerTitle: true,
        ),
        body: Consumer<CustomizeCompanionController>(
          builder: (context, controller, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // --- Cat Carousel ---
                  CatCarousel(
                    pageController: _pageController,
                    catImages: controller.catImages,
                    currentCatIndex: controller.currentCatIndex,
                    onPageChanged: controller.updateCatIndex,
                  ),

                  const SizedBox(height: 30),

                  // --- Name Section ---
                  NameSection(nameController: controller.nameController),

                  const SizedBox(height: 25),

                  // --- Personality Section ---
                  PersonalitySection(
                    personalities: controller.personalities,
                    selectedPersonality: controller.selectedPersonality,
                    isCustomPersonality: controller.isCustomPersonality,
                    isLoading: controller.isLoading,
                    onPersonalitySelected: controller.selectPersonality,
                    onCustomSelected: controller.selectCustomPersonality,
                    cardColor: _cardColor,
                    orangeColor: _orangeColor,
                  ),

                  // --- Custom Personality Card (Conditional) ---
                  if (controller.isCustomPersonality) ...[
                    const SizedBox(height: 20),
                    CustomPersonalityCard(
                      personalityNameController: controller.customPersonalityNameController,
                      descriptionController: controller.customDescriptionController,
                      cardColor: _cardColor,
                    ),
                  ],

                  const SizedBox(height: 25),

                  // --- Voice Tone Section ---
                  VoiceToneSection(
                    selectedVoiceTone: controller.selectedVoiceTone,
                    voiceTones: controller.voiceTones,
                    onChanged: controller.updateVoiceTone,
                  ),

                  const SizedBox(height: 25),

                  // --- Gender Section ---
                  GenderSection(
                    selectedGender: controller.selectedGender,
                    genders: controller.genders,
                    onChanged: controller.updateGender,
                  ),

                  const SizedBox(height: 40),

                  // --- Save Button ---
                  SaveButton(
                    isLoading: controller.isSaving,
                    onPressed: _handleSave,
                    buttonColor: _saveBtnColor,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}