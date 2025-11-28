import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../homepage_screen.dart';

class BookingSuccessScreen extends StatelessWidget {
  final String therapistName;
  final DateTime date;
  final String time;
  final double price;
  final String clientUserId;

  const BookingSuccessScreen({
    super.key,
    required this.therapistName,
    required this.date,
    required this.time,
    required this.price,
    required this.clientUserId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(247, 244, 242, 1),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              const Text(
                'Booking Successful!',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color.fromRGBO(66, 32, 6, 1),
                ),
              ),
              const SizedBox(height: 32),
              Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7), // Light green
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_rounded,
                    size: 64,
                    color: Color(0xFF22C55E), // Green
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Your session is confirmed',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color.fromRGBO(31, 41, 55, 1), // Dark grey/black
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "You'll receive a reminder one hour before your session.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 14,
                  color: Color.fromRGBO(107, 114, 128, 1), // Grey
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildDetailRow('Therapist', therapistName),
                    const SizedBox(height: 16),
                    _buildDetailRow('Date', DateFormat('MMMM d, yyyy').format(date)),
                    const SizedBox(height: 16),
                    _buildDetailRow('Time', time),
                    const SizedBox(height: 16),
                    _buildDetailRow('Price', 'RM ${price.toStringAsFixed(0)}'),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => HomeScreen(userId: clientUserId),
                      ),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(109, 76, 65, 1), // Brown
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Go to Homepage',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 14,
            color: Color.fromRGBO(156, 163, 175, 1), // Light grey
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color.fromRGBO(31, 41, 55, 1), // Dark grey/black
          ),
        ),
      ],
    );
  }
}
