import 'package:flutter/material.dart';

class MusicScreen extends StatelessWidget {
  const MusicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(247, 244, 242, 1),
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(247, 244, 242, 1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color.fromRGBO(66, 32, 6, 1)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Mindful Music',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.bold,
            color: Color.fromRGBO(66, 32, 6, 1),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Step away from the busy feed and give yourself a mindful listening break. '
            'Pick a session below and use your preferred music app to queue something similar.',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              color: Color.fromRGBO(92, 64, 51, 1),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          ..._musicSessions.map((session) => _MusicSessionCard(session: session)),
        ],
      ),
    );
  }
}

class _MusicSessionCard extends StatelessWidget {
  const _MusicSessionCard({required this.session});

  final _MusicSession session;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: session.accentColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  session.icon,
                  color: session.accentColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  session.title,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Color.fromRGBO(66, 32, 6, 1),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            session.description,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 13,
              height: 1.4,
              color: Color.fromRGBO(92, 64, 51, 1),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: session.accentColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              session.prompt,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                height: 1.4,
                color: session.accentColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              session.durationLabel,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                color: Color.fromRGBO(107, 114, 128, 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MusicSession {
  const _MusicSession({
    required this.title,
    required this.description,
    required this.prompt,
    required this.durationLabel,
    required this.icon,
    required this.accentColor,
  });

  final String title;
  final String description;
  final String prompt;
  final String durationLabel;
  final IconData icon;
  final Color accentColor;
}

const List<_MusicSession> _musicSessions = [
  _MusicSession(
    title: 'Gentle Sunrise',
    description: 'Soft piano or acoustic guitar to open the day with ease.',
    prompt: 'As you listen, track the rise and fall of the melody. Match your breathing to the tempo.',
    durationLabel: '4-6 minute session',
    icon: Icons.wb_sunny_outlined,
    accentColor: Color(0xFFF59E0B),
  ),
  _MusicSession(
    title: 'Lo-Fi Focus',
    description: 'Warm lo-fi beats to help you settle into deep work or journaling.',
    prompt: 'Notice the layers in the track. Each time you hear a new sound, relax your shoulders.',
    durationLabel: '8-10 minute session',
    icon: Icons.center_focus_strong,
    accentColor: Color(0xFF6366F1),
  ),
  _MusicSession(
    title: 'Evening Unwind',
    description: 'Calming ambient pads to slow down before rest.',
    prompt: 'Close your eyes and count each note that gently fades out. Let your thoughts drift away with it.',
    durationLabel: '6-8 minute session',
    icon: Icons.nightlight_round,
    accentColor: Color(0xFF10B981),
  ),
];
