import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/companion_model.dart';
import 'controllers/update_companion_controller.dart';
import 'widgets/widgets.dart';

class UpdateCompanionScreen extends StatefulWidget {
  final String userId;
  final Companion companion;

  const UpdateCompanionScreen({
    Key? key,
    required this.userId,
    required this.companion,
  }) : super(key: key);

  @override
  State<UpdateCompanionScreen> createState() => _UpdateCompanionScreenState();
}

class _UpdateCompanionScreenState extends State<UpdateCompanionScreen> {
  // --- Colors ---
  final Color _bgColor = const Color(0xFFF7F4F2);
  final Color _orangeColor = const Color(0xFFED7E1C);
  final Color _cardColor = const Color(0xFFFEEDE7);
  final Color _saveBtnColor = const Color(0xFF5D2D05);

  // --- Page Controller ---
  late PageController _pageController;
  late UpdateCompanionController _controller;

  @override
  void initState() {
    super.initState();
    _controller = UpdateCompanionController(
      userId: widget.userId,
      companion: widget.companion,
    );
    _pageController = PageController(viewportFraction: 0.45, initialPage: 0);

    _controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    // Only proceed if loading is done
    if (!_controller.isLoading) {
      final targetPage = _controller.currentCatIndex;
      
      // Schedule the check for AFTER the layout pass
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Now check if mounted and has clients (PageView is now built)
        if (mounted && _pageController.hasClients) {
          final currentPage = _pageController.page?.round() ?? 0;
          
          if (targetPage != currentPage) {
            _pageController.jumpToPage(targetPage);
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _pageController.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Handle update button press
  Future<void> _handleUpdate() async {
    final success = await _controller.updateCompanion();

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Companion updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true); // Return true to indicate update
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _controller.errorMessage ?? 'Failed to update companion',
          ),
          backgroundColor: Colors.red,
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
            'Update Companion',
            style: TextStyle(
              color: Color(0xFF5D2D05),
              fontWeight: FontWeight.w200,
              fontFamily: 'Urbanist',
              fontSize: 20,
            ),
          ),
          centerTitle: true,
        ),
        body: Consumer<UpdateCompanionController>(
          builder: (context, controller, child) {
            if (controller.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

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
                      personalityNameController:
                          controller.customPersonalityNameController,
                      descriptionController:
                          controller.customDescriptionController,
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

                  // --- Update Button ---
                  SaveButton(
                    isLoading: controller.isSaving,
                    onPressed: _handleUpdate,
                    buttonColor: _saveBtnColor,
                    buttonText: 'Update',
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
