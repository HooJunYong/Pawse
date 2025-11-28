import 'package:flutter/material.dart';
import '../../../models/mood_entry.dart';

/// Weekly line chart widget for mood tracking
class WeeklyChart extends StatelessWidget {
  final List<WeeklyChartDataPoint> chartData;

  // Colors
  static const Color _orangeColor = Color(0xFFF38025);

  const WeeklyChart({
    Key? key,
    required this.chartData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<int> moodValues = chartData.map((data) => data.moodValue).toList();
    final List<int> dayNumbers = chartData.map((data) => data.day).toList();

    const double chartHeight = 220.0;
    const double horizontalPadding = 20.0;
    const double emojiSize = 24.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Y Axis (Emojis)
        _buildYAxis(chartHeight, emojiSize),
        const SizedBox(width: 15),
        // Graph
        Expanded(
          child: Column(
            children: [
              SizedBox(
                height: chartHeight,
                width: double.infinity,
                child: CustomPaint(
                  painter: WeeklyChartPainter(
                    moodValues: moodValues,
                    orangeColor: _orangeColor,
                    bgColor: const Color(0xFFFFDAB9),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _buildXAxisLabels(dayNumbers, horizontalPadding),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildYAxis(double chartHeight, double emojiSize) {
    const double verticalPadding = 24.0;
    final double drawingHeight = chartHeight - (verticalPadding * 2);
    final double step = drawingHeight / 4.0;

    final moodAssets = [
      'assets/images/mood_very_happy.png',
      'assets/images/mood_happy.png',
      'assets/images/mood_neutral.png',
      'assets/images/mood_sad.png',
      'assets/images/mood_awful.png',
    ];

    return SizedBox(
      height: chartHeight,
      width: 24,
      child: Stack(
        children: List.generate(5, (index) {
          final topPosition = verticalPadding + (index * step) - (emojiSize / 2);
          return Positioned(
            top: topPosition,
            child: _buildAssetEmoji(moodAssets[index]),
          );
        }),
      ),
    );
  }

  Widget _buildXAxisLabels(List<int> dayNumbers, double horizontalPadding) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: dayNumbers
            .map((day) => SizedBox(
                  width: 20,
                  child: Text(
                    day.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildAssetEmoji(String path) {
    return SizedBox(
      height: 24,
      width: 24,
      child: Image.asset(
        path,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.error_outline, size: 24, color: Colors.grey);
        },
      ),
    );
  }
}

/// Custom Painter for Weekly Line Chart
class WeeklyChartPainter extends CustomPainter {
  final List<int> moodValues;
  final Color orangeColor;
  final Color bgColor;

  WeeklyChartPainter({
    required this.moodValues,
    required this.orangeColor,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Draw background
    final bgPaint = Paint()..color = bgColor;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, w, h), const Radius.circular(8)),
        bgPaint);

    const double verticalPadding = 24.0;
    final double drawingHeight = h - (verticalPadding * 2);

    const double horizontalPadding = 20.0;
    final double drawingWidth = w - (horizontalPadding * 2);
    final stepX = drawingWidth / 6;

    List<Offset?> points = [];
    for (int i = 0; i < moodValues.length && i < 7; i++) {
      final value = moodValues[i];
      if (value > 0) {
        final yPos = (h - verticalPadding) - ((value - 1) / 4) * drawingHeight;
        final xPos = horizontalPadding + (stepX * i);
        points.add(Offset(xPos, yPos));
      } else {
        points.add(null);
      }
    }

    // Draw connecting lines
    final linePaint = Paint()
      ..color = orangeColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final linePath = Path();
    bool pathStarted = false;

    for (int i = 0; i < points.length; i++) {
      if (points[i] != null) {
        if (!pathStarted) {
          linePath.moveTo(points[i]!.dx, points[i]!.dy);
          pathStarted = true;
        } else {
          linePath.lineTo(points[i]!.dx, points[i]!.dy);
        }
      }
    }

    if (pathStarted) {
      canvas.drawPath(linePath, linePaint);
    }

    // Draw dots
    for (var point in points) {
      if (point != null) {
        _drawDot(canvas, point);
      }
    }
  }

  void _drawDot(Canvas canvas, Offset center) {
    final whitePaint = Paint()..color = Colors.white;
    final borderPaint = Paint()
      ..color = orangeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(center, 6, whitePaint);
    canvas.drawCircle(center, 6, borderPaint);
  }

  @override
  bool shouldRepaint(covariant WeeklyChartPainter oldDelegate) {
    return oldDelegate.moodValues != moodValues;
  }
}
