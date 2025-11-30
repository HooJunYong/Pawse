import 'package:flutter/material.dart';

import '../../models/therapist_model.dart';
import '../../widgets/contact_row.dart';
import '../../widgets/expertise_chip.dart';
import '../chat/chat_screen.dart';
import 'booking_session_screen.dart';

// --- Theme Colors ---
const Color _bgWhite = Color(0xFFFDFCF8); // Soft cream background
const Color _primaryBrown = Color(0xFF5D4037); // Dark brown for headings/buttons
const Color _textDark = Color(0xFF3E2723); // Almost black brown for main text
const Color _textGrey = Color(0xFF8D6E63); // Warm grey for subtitles
const Color _accentOrange = Color(0xFFFFB74D); // Soft orange for icons/highlights
const Color _chipBg = Color(0xFFFFF3E0); // Very light orange for chips

// --- Shadows ---
final List<BoxShadow> _softShadow = [
  BoxShadow(
    color: const Color(0xFF5D4037).withOpacity(0.08), // Brown-tinted shadow
    blurRadius: 20,
    offset: const Offset(0, 8),
  ),
];

class TherapistInfoScreen extends StatelessWidget {
  final Therapist therapist;
  final String clientUserId;

  const TherapistInfoScreen({
    super.key,
    required this.therapist,
    required this.clientUserId,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasRating = therapist.ratingCount > 0;
    final String ratingLabel =
        hasRating ? therapist.rating.toStringAsFixed(1) : 'New';
    final String ratingCountLabel = hasRating
        ? '${therapist.ratingCount} review${therapist.ratingCount == 1 ? '' : 's'}'
        : 'No ratings yet';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4F2), // Main background
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: _primaryBrown),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 375),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Header & Profile Pic
                SizedBox(
                  height: 340,
                  child: Stack(
                    children: [
                      // Gradient Background
                      Container(
                        height: 260,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFFFFECB3), // Light Amber
                              Color(0xFFFFCC80), // Orange Accent
                            ],
                          ),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(40),
                            bottomRight: Radius.circular(40),
                          ),
                        ),
                      ),
                      // Info Card
                      Positioned(
                        top: 100,
                        left: 24,
                        right: 24,
                        child: Container(
                          padding: const EdgeInsets.only(
                              top: 60, bottom: 24, left: 20, right: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: _softShadow,
                          ),
                          child: Column(
                            children: [
                              Text(
                                therapist.displayName,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: _textDark,
                                  fontFamily: 'Nunito',
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.business,
                                      size: 16, color: _textGrey),
                                  const SizedBox(width: 6),
                                  Text(
                                    therapist.centerName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _textGrey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                therapist.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _textGrey.withOpacity(0.8),
                                ),
                              ),
                              const SizedBox(height: 20),
                              
                              // Rating Pill
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: _bgWhite,
                                  borderRadius: BorderRadius.circular(50),
                                  border: Border.all(
                                      color: _primaryBrown.withOpacity(0.1)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star_rounded,
                                        color: Colors.amber, size: 22),
                                    const SizedBox(width: 6),
                                    Text(
                                      hasRating
                                          ? '$ratingLabel Rating'
                                          : ratingLabel,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _textDark,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 12),
                                      height: 14,
                                      width: 1,
                                      color: Colors.grey.shade300,
                                    ),
                                    Text(
                                      ratingCountLabel,
                                      style: const TextStyle(
                                        color: _textGrey,
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (hasRating) ...[
                                      Container(
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 12),
                                        height: 14,
                                        width: 1,
                                        color: Colors.grey.shade300,
                                      ),
                                      const Icon(Icons.verified,
                                          color: Colors.blueAccent, size: 18),
                                    ]
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Profile Image
                      Positioned(
                        top: 60,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(4),
                            child: CircleAvatar(
                              radius: 48,
                              backgroundColor: const Color(0xFFFFF3E0),
                              // You might want to switch to NetworkImage if available
                              // backgroundImage: NetworkImage(therapist.imageUrl),
                              child: Text(
                                therapist.imageUrl, // Fallback initials
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: _primaryBrown,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Main Content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quote
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _chipBg.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '"${therapist.quote}"',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: _textGrey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      
                      // Areas of Expertise
                      _buildSectionTitle("Areas of Expertise"),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: therapist.specialties
                            .split(',')
                            .map((s) => ExpertiseChip(label: s.trim()))
                            .toList(),
                      ),
                      
                      const SizedBox(height: 28),
                      
                      // Languages Spoken
                      _buildSectionTitle("Languages Spoken"),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: therapist.languages
                            .split(',')
                            .map((lang) => LanguageChip(label: lang.trim()))
                            .toList(),
                      ),
                      
                      const SizedBox(height: 28),
                      
                      // Contact & Location
                      _buildSectionTitle("Contact & Location"),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: _softShadow,
                        ),
                        child: Column(
                          children: [
                            ContactRow(
                              icon: Icons.phone_rounded,
                              text: "012-345 6789",
                              iconColor: _accentOrange,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Divider(
                                  height: 1,
                                  color: _primaryBrown.withOpacity(0.1)),
                            ),
                            ContactRow(
                              icon: Icons.location_on_rounded,
                              text: therapist.address,
                              iconColor: _accentOrange,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 28),
                      
                      // Availability
                      _buildSectionTitle("Availability"),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 18, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: _primaryBrown.withOpacity(0.1)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.event_available,
                                color: _primaryBrown, size: 20),
                            const SizedBox(width: 8),
                            RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                    color: _textDark,
                                    fontSize: 14,
                                    fontFamily: 'Nunito'),
                                children: [
                                  TextSpan(text: "Next available: "),
                                  TextSpan(
                                    text: "Tomorrow, 3:00 PM",
                                    style: TextStyle(
                                      color: Color(0xFFD84315), // Deep orange
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Booking Footer
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: _softShadow,
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'RM ${therapist.price.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: _textDark,
                                      ),
                                    ),
                                    const Text(
                                      "per hour session",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _textGrey,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    final booked = await Navigator.push<bool>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            BookingSessionScreen(
                                          therapist: therapist,
                                          clientUserId: clientUserId,
                                        ),
                                      ),
                                    );

                                    if (booked == true) {
                                      Navigator.pop(context, true);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _primaryBrown,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 32, vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    "Book Session",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: TextButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => ChatScreen(
                                        conversationId: null,
                                        clientUserId: clientUserId,
                                        therapistUserId: therapist.id,
                                        currentUserId: clientUserId,
                                        isTherapist: false,
                                        counterpartName: therapist.displayName,
                                        counterpartAvatarUrl: therapist.imageUrl,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.chat_bubble_outline_rounded,
                                    size: 20),
                                label: const Text("Free Consultation"),
                                style: TextButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFE0B2),
                                  foregroundColor: _primaryBrown,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: _textDark,
        letterSpacing: 0.5,
      ),
    );
  }
}