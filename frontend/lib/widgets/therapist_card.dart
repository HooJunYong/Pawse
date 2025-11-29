import 'package:flutter/material.dart';

import '../models/therapist_model.dart';
import '../screens/therapist/therapist_info_screen.dart';

class TherapistCard extends StatelessWidget {
  final Therapist therapist;
  final String clientUserId;
  final VoidCallback? onSessionBooked;

  const TherapistCard({
    super.key,
    required this.therapist,
    required this.clientUserId,
    this.onSessionBooked,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasRating = therapist.ratingCount > 0;
    final String ratingLabel = hasRating
        ? therapist.rating.toStringAsFixed(1)
        : 'New';
    final String ratingCountLabel = hasRating ? ' (${therapist.ratingCount})' : '';

    return GestureDetector(
      onTap: () async {
        final booked = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => TherapistInfoScreen(
              therapist: therapist,
              clientUserId: clientUserId,
            ),
          ),
        );
        if (booked == true) {
          onSessionBooked?.call();
        }
      },
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: const Color(0xFFFDFCF8), // Very light bg
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade100, width: 1),
              ),
              child: Text(
                therapist.imageUrl, // Using text initials as per UI
                style: const TextStyle(
                  color: Color(0xFF4E342E),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        therapist.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF263238),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          '$ratingLabel$ratingCountLabel',
                          style: const TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  therapist.specialties,
                  style: TextStyle(
                    color: Colors.blueGrey[600],
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        therapist.location,
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.chat_bubble, size: 14, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        therapist.languages,
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    ),
    );
  }
}
