import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../utils/helpers.dart';
import '../controllers/mood_tracking_controller.dart';
import 'weekly_chart.dart';
import 'monthly_chart.dart';

/// Card widget containing the mood chart with toggle between weekly and monthly views
class MoodChartCard extends StatelessWidget {
  final MoodTrackingController controller;
  final GlobalKey chartKey;

  // Colors
  static const Color _orangeColor = Color(0xFFF38025);

  const MoodChartCard({
    Key? key,
    required this.controller,
    required this.chartKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: chartKey,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Column(
          children: [
            // Header
            _buildHeader(context),
            const SizedBox(height: 20),

            // Toggle Switch
            _buildToggleSwitch(),
            const SizedBox(height: 15),

            // Date Range Navigation
            _buildDateRangeNavigation(),
            const SizedBox(height: 20),

            // Chart Area
            _buildChartArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Mood Chart",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        GestureDetector(
          onTap: () => _downloadChart(context),
          child: const Icon(Icons.download_rounded, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildToggleSwitch() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          _buildToggleButton(
            label: "Weekly",
            isSelected: controller.isWeeklyChart,
            onTap: () => controller.setWeeklyChart(true),
          ),
          _buildToggleButton(
            label: "Monthly",
            isSelected: !controller.isWeeklyChart,
            onTap: () => controller.setWeeklyChart(false),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? _orangeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateRangeNavigation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: controller.isWeeklyChart
              ? controller.goToPreviousWeek
              : controller.goToPreviousChartMonth,
          child: const Icon(Icons.arrow_back_ios, size: 14),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Text(
            controller.isWeeklyChart
                ? controller.getWeekRangeString()
                : controller.getChartMonthString(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
        GestureDetector(
          onTap: controller.isWeeklyChart
              ? controller.goToNextWeek
              : controller.goToNextChartMonth,
          child: const Icon(Icons.arrow_forward_ios, size: 14),
        ),
      ],
    );
  }

  Widget _buildChartArea() {
    if (controller.isChartLoading) {
      return const SizedBox(
        height: 250,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (controller.isWeeklyChart) {
      return WeeklyChart(chartData: controller.weeklyChartData);
    } else {
      return MonthlyChart(moodStats: controller.monthlyMoodStats);
    }
  }

  Future<void> _downloadChart(BuildContext context) async {
    try {
      // Request storage permission
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          final mediaStatus = await Permission.photos.request();
          if (!mediaStatus.isGranted) {
            Helpers.showErrorSnackbar(
                context, 'Storage permission is required to save the chart');
            return;
          }
        }
      }

      // Capture the chart as image
      RenderRepaintBoundary boundary =
          chartKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      // Save to Pictures directory
      final directory = await getExternalStorageDirectory();
      final picturesDir = Directory(
          '${directory!.parent.parent.parent.parent.path}/Pictures/Pawse');
      if (!await picturesDir.exists()) {
        await picturesDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final chartType = controller.isWeeklyChart ? 'weekly' : 'monthly';
      final file =
          File('${picturesDir.path}/mood_chart_${chartType}_$timestamp.png');
      await file.writeAsBytes(pngBytes);

      if (context.mounted) {
        Helpers.showSuccessSnackbar(context, 'Chart saved to Gallery!');
      }
    } catch (e) {
      debugPrint('Error saving chart: $e');
      if (context.mounted) {
        Helpers.showErrorSnackbar(context, 'Failed to save chart');
      }
    }
  }
}
