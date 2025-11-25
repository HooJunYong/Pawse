import 'package:flutter/material.dart';
import 'dart:math' as math;

class TypingIndicator extends StatefulWidget {
  final Color color;
  final double size;

  const TypingIndicator({
    super.key,
    this.color = Colors.grey,
    this.size = 6.0,
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // A fast repeating animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 5, // Reserve space for 3 dots + spacing
      height: widget.size * 3, // Reserve vertical space for bouncing
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // We create 3 dots
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(3, (index) {
              // Calculate a delay for each dot so they don't bounce together
              // We use a Sine wave: sin(2*pi*t)
              final delay = index * 0.5; 
              final value = math.sin((_controller.value * 2 * math.pi) - delay);
              
              // Map the -1 to 1 sine wave to a 0 to 1 vertical offset
              final offset = (value + 1) / 2; 

              return Transform.translate(
                // Move up and down by half the size
                offset: Offset(0, -offset * widget.size),
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}