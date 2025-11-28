import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/therapist_model.dart';
import '../../services/booking_service.dart';
import 'booking_success_screen.dart';

const Color _backgroundColor = Color.fromRGBO(247, 244, 242, 1);
const Color _primaryColor = Color.fromRGBO(249, 115, 22, 1);
const Color _primaryMuted = Color.fromRGBO(249, 115, 22, 0.2);
const Color _textPrimary = Color.fromRGBO(66, 32, 6, 1);
const Color _textSecondary = Color.fromRGBO(107, 114, 128, 1);

class BookingSessionScreen extends StatefulWidget {
  final Therapist therapist;
  final String clientUserId;

  const BookingSessionScreen({
    super.key,
    required this.therapist,
    required this.clientUserId,
  });

  @override
  State<BookingSessionScreen> createState() => _BookingSessionScreenState();
}

class _BookingSessionScreenState extends State<BookingSessionScreen> {
  DateTime _selectedDate = DateTime.now();
  AvailableTimeSlot? _selectedTimeSlot;
  
  final BookingService _bookingService = BookingService();
  TherapistAvailability? _availability;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final availability = await _bookingService.getTherapistAvailability(
        widget.therapist.id,
        dateStr,
      );
      setState(() {
        _availability = availability;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading availability: $e')),
        );
      }
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month + delta,
        1,
      );
      _loadAvailability();
    });
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
      _selectedTimeSlot = null;
    });
    _loadAvailability();
  }

  DateTime _parseSlotTime(String timeStr) {
    final time = DateFormat('h:mm a').parse(timeStr);
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      time.hour,
      time.minute,
    );
  }

  int _calculateDurationMinutes(AvailableTimeSlot slot) {
    final start = _parseSlotTime(slot.startTime);
    final end = _parseSlotTime(slot.endTime);
    return end.difference(start).inMinutes;
  }

  double _calculateSlotPrice(AvailableTimeSlot slot) {
    final hourlyRate = _availability?.price ?? widget.therapist.price;
    final minutes = _calculateDurationMinutes(slot);
    final hours = minutes / 60.0;
    return hourlyRate * hours;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Booking Session',
          style: TextStyle(
            fontFamily: 'Nunito',
            color: _textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 375),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Calendar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Month Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: () => _changeMonth(-1),
                              color: _textPrimary,
                            ),
                            Text(
                              DateFormat('MMMM yyyy').format(_selectedDate),
                              style: const TextStyle(
                                fontSize: 16,
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.bold,
                                color: _textPrimary,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: () => _changeMonth(1),
                              color: _textPrimary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Day Labels
                        Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Row(
                            children: [
                              ...['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'].map(
                                (day) => Row(
                                  children: [
                                    SizedBox(
                                      width: 32,
                                      child: Text(
                                        day,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontFamily: 'Nunito',
                                          fontWeight: FontWeight.w600,
                                          color: _textSecondary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Calendar Grid
                        _buildCalendarGrid(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Available Times
                  Text(
                    'Available Times on ${DateFormat('MMM d').format(_selectedDate)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.bold,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _isLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(
                              color: _primaryColor,
                            ),
                          ),
                        )
                      : _availability == null || _availability!.availableSlots.isEmpty
                          ? SizedBox(
                              width: double.infinity,
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'No available times for this date',
                                  style: TextStyle(
                                    color: _textSecondary,
                                    fontFamily: 'Nunito',
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            )
                          : LayoutBuilder(
                              builder: (context, constraints) {
                                final slots = _availability!.availableSlots;
                                final double spacing = 12;
                                final double maxWidth = constraints.maxWidth;
                                final double itemWidth =
                                    (maxWidth - (spacing * 2)) / 3; // 3 items per row

                                return Wrap(
                                  spacing: spacing,
                                  runSpacing: spacing,
                                  children: slots.map((slot) {
                                    final isSelected = _selectedTimeSlot?.slotId == slot.slotId;
                                    final isDisabled = !slot.isAvailable;

                                    final Color backgroundColor;
                                    final Color borderColor;
                                    final Color textColor;

                                    if (isDisabled) {
                                      backgroundColor = const Color(0xFFE5E7EB);
                                      borderColor = Colors.transparent;
                                      textColor = _textSecondary.withOpacity(0.5);
                                    } else if (isSelected) {
                                      backgroundColor = _primaryColor;
                                      borderColor = _primaryColor;
                                      textColor = Colors.white;
                                    } else {
                                      backgroundColor = Colors.white;
                                      borderColor = _primaryMuted;
                                      textColor = _textPrimary;
                                    }

                                    return SizedBox(
                                      width: itemWidth,
                                      child: GestureDetector(
                                        onTap: isDisabled
                                            ? null
                                            : () {
                                                setState(() {
                                                  _selectedTimeSlot = slot;
                                                });
                                              },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                          decoration: BoxDecoration(
                                                  color: backgroundColor,
                                            borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(color: borderColor),
                                          ),
                                          child: Center(
                                            child: Text(
                                              slot.startTime,
                                              style: TextStyle(
                                                      color: textColor,
                                                fontFamily: 'Nunito',
                                                      fontWeight: isSelected
                                                          ? FontWeight.bold
                                                          : FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                  const SizedBox(height: 24),

                  // Summary
                  const Text(
                    'Summary',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.bold,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildSummaryRow('Therapist', widget.therapist.name),
                        const SizedBox(height: 12),
                        _buildSummaryRow(
                          'Date',
                          '${_getMonthName(_selectedDate.month)} ${_selectedDate.day}, ${_selectedDate.year}',
                        ),
                        const SizedBox(height: 12),
                        _buildSummaryRow(
                          'Time',
                          _selectedTimeSlot != null
                              ? '${_selectedTimeSlot!.startTime} - ${_selectedTimeSlot!.endTime}'
                              : '-',
                        ),
                        const SizedBox(height: 12),
                        _buildSummaryRow(
                          'Price',
                          _selectedTimeSlot != null
                              ? 'RM ${_calculateSlotPrice(_selectedTimeSlot!).toStringAsFixed(0)}'
                              : 'RM ${(_availability?.price ?? widget.therapist.price).toStringAsFixed(0)}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Confirm Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _selectedTimeSlot != null
                          ? () {
                              _showConfirmationDialog(context);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        disabledBackgroundColor: const Color.fromRGBO(249, 115, 22, 0.3),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Confirm Booking',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          color: _selectedTimeSlot != null ? Colors.white : Colors.white.withOpacity(0.7),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final lastDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final firstWeekday = firstDayOfMonth.weekday % 7; // 0 = Sunday

    final List<Widget> dayWidgets = [];

    // Add empty cells for days before month starts
    for (int i = 0; i < firstWeekday; i++) {
      dayWidgets.add(const SizedBox(width: 32, height: 32));
    }

    // Add day cells
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_selectedDate.year, _selectedDate.month, day);
      final isSelected = date.year == _selectedDate.year &&
          date.month == _selectedDate.month &&
          date.day == _selectedDate.day;
      final isToday = date.year == DateTime.now().year &&
          date.month == DateTime.now().month &&
          date.day == DateTime.now().day;
      final isPast = date.isBefore(DateTime.now().subtract(const Duration(days: 1)));

      dayWidgets.add(
        GestureDetector(
          onTap: isPast ? null : () => _selectDate(date),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isSelected
                  ? _primaryColor
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Nunito',
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  color: isPast
                      ? _textSecondary.withOpacity(0.4)
                      : isSelected
                          ? Colors.white
                          : _textPrimary,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Wrap(spacing: 8, runSpacing: 8, children: dayWidgets),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _textSecondary,
            fontFamily: 'Nunito',
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: _textPrimary,
            fontFamily: 'Nunito',
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  void _showConfirmationDialog(BuildContext context) {
    if (_selectedTimeSlot == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Confirm Booking',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Nunito',
              color: _textPrimary,
            ),
          ),
          content: Text(
            'Are you sure you want to book a session with ${widget.therapist.name} on ${_getMonthName(_selectedDate.month)} ${_selectedDate.day}, ${_selectedDate.year} from ${_selectedTimeSlot!.startTime} to ${_selectedTimeSlot!.endTime}?',
            style: TextStyle(
              color: _textSecondary,
              fontFamily: 'Nunito',
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: _textSecondary,
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog first

                final messenger = ScaffoldMessenger.of(this.context);
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Creating booking...'),
                    duration: Duration(seconds: 4),
                  ),
                );

                try {
                  final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

                  await _bookingService.createBooking(
                    clientUserId: widget.clientUserId,
                    therapistUserId: widget.therapist.id,
                    date: dateStr,
                    startTime: _selectedTimeSlot!.startTime,
                    durationMinutes: _calculateDurationMinutes(_selectedTimeSlot!),
                    sessionType: 'in_person',
                  );

                  messenger.hideCurrentSnackBar();
                  if (!mounted) return;
                  final price = _calculateSlotPrice(_selectedTimeSlot!);
                  Navigator.of(this.context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => BookingSuccessScreen(
                        therapistName: widget.therapist.name,
                        date: _selectedDate,
                        time: '${_selectedTimeSlot!.startTime}',
                        price: price,
                        clientUserId: widget.clientUserId,
                      ),
                    ),
                  );
                } catch (e) {
                  messenger.hideCurrentSnackBar();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Failed to create booking: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Confirm',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
