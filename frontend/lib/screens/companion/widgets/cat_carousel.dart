import 'package:flutter/material.dart';

/// Cat carousel widget for selecting companion image
class CatCarousel extends StatelessWidget {
  final PageController pageController;
  final List<String> catImages;
  final int currentCatIndex;
  final Function(int) onPageChanged;

  const CatCarousel({
    super.key,
    required this.pageController,
    required this.catImages,
    required this.currentCatIndex,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The PageView
          PageView.builder(
            controller: pageController,
            itemCount: catImages.length,
            onPageChanged: onPageChanged,
            itemBuilder: (context, index) {
              bool isCenter = index == currentCatIndex;

              return AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: isCenter ? 1.0 : 0.4,
                child: Transform.scale(
                  scale: isCenter ? 1.2 : 0.9,
                  child: Image.asset(
                    catImages[index],
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.pets, size: 50, color: Colors.grey);
                    },
                  ),
                ),
              );
            },
          ),

          // Navigation Arrows
          Positioned(
            left: 40,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 30),
              color: Colors.black87,
              onPressed: () {
                pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
            ),
          ),
          Positioned(
            right: 40,
            child: IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 30),
              color: Colors.black87,
              onPressed: () {
                pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
