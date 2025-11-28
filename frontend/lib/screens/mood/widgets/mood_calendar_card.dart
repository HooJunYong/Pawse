import 'package:flutter/material.dart';
import '../controllers/mood_tracking_controller.dart';
import 'mood_day_cell.dart';

/// Calendar card widget for displaying mood entries in a monthly calendar view
class MoodCalendarCard extends StatelessWidget {
  final MoodTrackingController controller;
  final Function(DateTime date, Map<String, dynamic>? moodEntry) onDayTapped;

  const MoodCalendarCard({
    Key? key,
    required this.controller,
    required this.onDayTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate calendar grid
    final displayedMonth = controller.displayedMonth;
    final firstDayOfMonth = DateTime(displayedMonth.year, displayedMonth.month, 1);
    final lastDayOfMonth = DateTime(displayedMonth.year, displayedMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;

    // Calculate what day of week the month starts on (1 = Monday, 7 = Sunday)
    int startWeekday = firstDayOfMonth.weekday;

    // Calculate total cells needed (including empty cells at start)
    int totalCells = startWeekday - 1 + daysInMonth;
    int rows = (totalCells / 7).ceil();
    int gridItemCount = rows * 7;

    return Container(
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
          // Month Header
          _buildMonthHeader(),
          const SizedBox(height: 15),

          // Days of Week
          _buildWeekdayHeader(),
          const SizedBox(height: 15),

          // Loading indicator or Calendar Grid
          if (controller.isLoading)
            const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            )
          else
            _buildCalendarGrid(
              gridItemCount: gridItemCount,
              startWeekday: startWeekday,
              daysInMonth: daysInMonth,
            ),

          const SizedBox(height: 15),
          const Text(
            "Tap mood to see more details",
            style: TextStyle(color: Colors.black87, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black87),
          onPressed: controller.goToPreviousMonth,
        ),
        Text(
          controller.getMonthYearString(),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.black87),
          onPressed: controller.goToNextMonth,
        ),
      ],
    );
  }

  Widget _buildWeekdayHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
          .map((day) => SizedBox(
                width: 35,
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black87, fontSize: 13),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildCalendarGrid({
    required int gridItemCount,
    required int startWeekday,
    required int daysInMonth,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: gridItemCount,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 6,
        crossAxisSpacing: 4,
        childAspectRatio: 0.65,
      ),
      itemBuilder: (context, index) {
        // Calculate day from index
        int day = index - (startWeekday - 2);

        // Empty cells before month starts or after month ends
        if (index < startWeekday - 1 || day > daysInMonth) {
          return const SizedBox();
        }

        final cellDate = DateTime(
          controller.displayedMonth.year,
          controller.displayedMonth.month,
          day,
        );
        final moodEntry = controller.getMoodForDate(cellDate);

        return MoodDayCell(
          date: cellDate,
          moodEntry: moodEntry?.toDisplayMap(),
          isFuture: controller.isFutureDate(cellDate),
          isToday: controller.isToday(cellDate),
          onTap: () => onDayTapped(cellDate, moodEntry?.toDisplayMap()),
        );
      },
    );
  }
}
