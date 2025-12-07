import 'dart:convert';
import 'dart:typed_data';

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

    final avatarImage = _buildAvatarImage(therapist.imageUrl);

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
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade100, width: 1),
            ),
            child: CircleAvatar(
              radius: 32,
              backgroundColor: const Color(0xFFFDFCF8),
              backgroundImage: avatarImage,
              child: avatarImage == null
                  ? Text(
                      therapist.initials,
                      style: const TextStyle(
                        color: Color(0xFF4E342E),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    )
                  : null,
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

    ImageProvider? _buildAvatarImage(String? source) {
      if (source == null || source.isEmpty) {
        return null;
      }
      if (_isDataUri(source)) {
        final bytes = _decodeDataUri(source);
        if (bytes != null && bytes.isNotEmpty) {
          return MemoryImage(bytes);
        }
        return null;
      }
      return NetworkImage(source);
    }

    bool _isDataUri(String? value) {
      if (value == null) {
        return false;
      }
      final lower = value.toLowerCase();
      return lower.startsWith('data:image/');
    }

    Uint8List? _decodeDataUri(String dataUri) {
      final separator = dataUri.indexOf(',');
      if (separator == -1 || separator == dataUri.length - 1) {
        return null;
      }
      final payload = dataUri.substring(separator + 1).trim();
      try {
        return base64Decode(payload);
      } catch (_) {
        return null;
      }
    }
}
