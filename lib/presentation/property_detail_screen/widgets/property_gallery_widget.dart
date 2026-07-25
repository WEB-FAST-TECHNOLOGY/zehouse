import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../widgets/custom_image_widget.dart';

class PropertyGalleryWidget extends StatelessWidget {
  final List<Map<String, dynamic>> images;
  final int currentIndex;
  final Function(int) onPageChanged;
  final bool isTablet;

  const PropertyGalleryWidget({
    super.key,
    required this.images,
    required this.currentIndex,
    required this.onPageChanged,
    this.isTablet = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView.builder(
          itemCount: images.length,
          onPageChanged: onPageChanged,
          itemBuilder: (context, index) {
            return CustomImageWidget(
              imageUrl: images[index]['url'] as String,
              width: double.infinity,
              height: isTablet ? double.infinity : 300,
              fit: BoxFit.cover,
              semanticLabel: images[index]['semanticLabel'] as String,
            );
          },
        ),
        // Gradient overlay
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withAlpha(102), Colors.transparent],
              ),
            ),
          ),
        ),
        // Image counter
        Positioned(
          bottom: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(140),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              '${currentIndex + 1} / ${images.length}',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
        // Dot indicators
        Positioned(
          bottom: 14,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(images.length, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: currentIndex == index ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: currentIndex == index
                      ? Colors.white
                      : Colors.white.withAlpha(128),
                  borderRadius: BorderRadius.circular(100),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
