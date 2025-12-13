import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/therapist_model.dart';
import '../../services/booking_service.dart';
import '../../services/session_event_bus.dart';
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
  Set<String> _datesWithAvailability = {};
  Timer? _refreshTimer;
  StreamSubscription<SessionEvent>? _sessionEventSubscription;

  @override
  void initState() {
    super.initState();
    _loadMonthAvailability();
    _loadAvailability();
    _setupRealtimeUpdates();
  }

  void _setupRealtimeUpdates() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) _loadAvailability(silent: true);
    });

    _sessionEventSubscription = SessionEventBus.instance.stream.listen((event) {
      if (mounted && event.therapistUserId == widget.therapist.id) {
        _loadAvailability(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _sessionEventSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadAvailability({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      print('=== BOOKING SCREEN DEBUG ===');
      print('Loading availability for therapist: ${widget.therapist.id}');
      print('Selected date: $dateStr');
      
      final availability = await _bookingService.getTherapistAvailability(
        widget.therapist.id,
        dateStr,
      );
      
      print('Received availability response:');
      print('  - Therapist: ${availability.therapistName}');
      print('  - Date: ${availability.date}');
      print('  - Total slots: ${availability.availableSlots.length}');
      for (var slot in availability.availableSlots) {
        print('    * ${slot.startTime} - ${slot.endTime}, available: ${slot.isAvailable}');
      }
      
      setState(() {
        _availability = availability;
        if (_selectedTimeSlot != null) {
          AvailableTimeSlot? refreshedSlot;
          for (final slot in availability.availableSlots) {
            if (slot.slotId == _selectedTimeSlot!.slotId) {
              refreshedSlot = slot;
              break;
            }
          }
          if (refreshedSlot != null && _isSlotBookable(refreshedSlot)) {
            _selectedTimeSlot = refreshedSlot;
          } else {
            _selectedTimeSlot = null;
          }
        }
        if (!silent) _isLoading = false;
      });
    } catch (e) {
      print('ERROR loading availability: $e');
      if (!silent) {
        setState(() {
          _isLoading = false;
        });
        // Don't show error snackbar for silent refreshes
        // User can still see the error in logs if needed
      }
    }
  }

  Future<void> _loadMonthAvailability() async {
    try {
      final dates = await _bookingService.getTherapistScheduledDates(
        widget.therapist.id,
        _selectedDate.year,
        _selectedDate.month,
      );
      if (!mounted) return;
      setState(() {
        _datesWithAvailability = dates;
      });
    } catch (e) {
      print('Failed to load monthly availability: $e');
    }
  }

  void _changeMonth(int delta) {
    final DateTime newDate = DateTime(
      _selectedDate.year,
      _selectedDate.month + delta,
      1,
    );

    setState(() {
      _selectedDate = newDate;
      _selectedTimeSlot = null;
    });

    _loadMonthAvailability();
    _loadAvailability();
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

  bool _isSlotBookable(AvailableTimeSlot slot) {
    final slotStart = _parseSlotTime(slot.startTime);
    return slot.isAvailable && slotStart.isAfter(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final bool hasValidSelectedSlot =
        _selectedTimeSlot != null && _isSlotBookable(_selectedTimeSlot!);
    final AvailableTimeSlot? effectiveSelectedSlot =
        hasValidSelectedSlot ? _selectedTimeSlot : null;

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
                                    final isSelected = effectiveSelectedSlot?.slotId == slot.slotId;
                                    final DateTime slotStart = _parseSlotTime(slot.startTime);
                                    final bool isPastSlot = !slotStart.isAfter(DateTime.now());
                                    final bool isDisabled = !slot.isAvailable || isPastSlot;

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
                                                  if (!_isSlotBookable(slot)) {
                                                    _selectedTimeSlot = null;
                                                  }
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
                        _buildSummaryRow('Therapist', widget.therapist.displayName),
                        const SizedBox(height: 12),
                        _buildSummaryRow(
                          'Date',
                          '${_getMonthName(_selectedDate.month)} ${_selectedDate.day}, ${_selectedDate.year}',
                        ),
                        const SizedBox(height: 12),
                        _buildSummaryRow(
                          'Time',
                            effectiveSelectedSlot != null
                              ? '${effectiveSelectedSlot.startTime} - ${effectiveSelectedSlot.endTime}'
                              : '-',
                        ),
                        const SizedBox(height: 12),
                        _buildSummaryRow(
                          'Price',
                            effectiveSelectedSlot != null
                              ? 'RM ${_calculateSlotPrice(effectiveSelectedSlot).toStringAsFixed(0)}'
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
                      onPressed: effectiveSelectedSlot != null
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
                          color: effectiveSelectedSlot != null ? Colors.white : Colors.white.withOpacity(0.7),
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
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final isSelected = date.year == _selectedDate.year &&
          date.month == _selectedDate.month &&
          date.day == _selectedDate.day;
      final isToday = date.year == DateTime.now().year &&
          date.month == DateTime.now().month &&
          date.day == DateTime.now().day;
      final isPast = date.isBefore(DateTime.now().subtract(const Duration(days: 1)));
      final hasAvailability = _datesWithAvailability.contains(dateStr);

      dayWidgets.add(
        GestureDetector(
          onTap: isPast ? null : () => _selectDate(date),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isSelected
                  ? _primaryColor
                  : hasAvailability
                      ? _primaryMuted
                      : Colors.transparent,
              shape: BoxShape.circle,
              border: hasAvailability && !isSelected
                  ? Border.all(
                      color: _primaryColor.withOpacity(0.4),
                      width: 2,
                    )
                  : null,
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
                          : hasAvailability
                              ? _primaryColor
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
    final slot = _selectedTimeSlot;
    if (slot == null || !_isSlotBookable(slot)) {
      setState(() {
        _selectedTimeSlot = null;
      });
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.white,
          elevation: 8,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: _primaryMuted,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.event_available,
                      color: _primaryColor,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Title
                  const Text(
                    'Confirm Booking',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Nunito',
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Subtitle
                  const Text(
                    'Please review your booking details',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Nunito',
                      color: _textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Booking Details Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _backgroundColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _primaryMuted,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow(
                          Icons.person_outline,
                          'Therapist',
                          widget.therapist.displayName,
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow(
                          Icons.calendar_today,
                          'Date',
                          '${_getMonthName(_selectedDate.month)} ${_selectedDate.day}, ${_selectedDate.year}',
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow(
                          Icons.access_time,
                          'Time',
                          '${slot.startTime} - ${slot.endTime}',
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow(
                          Icons.payments_outlined,
                          'Total Price',
                          'RM ${_calculateSlotPrice(slot).toStringAsFixed(0)}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: BorderSide(
                              color: _textSecondary.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: _textSecondary,
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
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
                  final currentSlot = _selectedTimeSlot;
                  if (currentSlot == null || !_isSlotBookable(currentSlot)) {
                    messenger.hideCurrentSnackBar();
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Selected slot is no longer available.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  await _bookingService.createBooking(
                    clientUserId: widget.clientUserId,
                    therapistUserId: widget.therapist.id,
                    date: dateStr,
                    startTime: currentSlot.startTime,
                    durationMinutes: _calculateDurationMinutes(currentSlot),
                    sessionType: 'in_person',
                  );

                  messenger.hideCurrentSnackBar();
                  if (!mounted) return;
                  final price = _calculateSlotPrice(currentSlot);
                  Navigator.of(this.context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => BookingSuccessScreen(
                        therapistName: widget.therapist.displayName,
                        date: _selectedDate,
                        time: currentSlot.startTime,
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
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                shadowColor: _primaryColor.withOpacity(0.4),
              ),
              child: const Text(
                'Confirm',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 28),
    ],
  ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: _primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'Nunito',
                  color: _textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontFamily: 'Nunito',
                  color: _textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
  