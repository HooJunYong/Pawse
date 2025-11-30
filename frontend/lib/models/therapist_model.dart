// Therapist data model for therapist list
class Therapist {
  final String id;
  final String name;
  final String specialties;
  final String location; // State for list view
  final String address; // Full address for detail view
  final String languages;
  final double rating;
  final int ratingCount;
  final String? imageUrl;
  final String initials;
  final String title;
  final String centerName; // Center/Clinic name
  final String quote;
  final double price;

  Therapist({
    required this.id,
    required this.name,
    required this.specialties,
    required this.location,
    required this.address,
    required this.languages,
    required this.rating,
    required this.ratingCount,
    this.imageUrl,
    required this.initials,
    required this.title,
    required this.centerName,
    required this.quote,
    required this.price,
  });

  String get displayName {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return 'Dr.';
    }
    final lower = trimmed.toLowerCase();
    final hasDoctorPrefix = lower.startsWith('dr. ') ||
        lower.startsWith('dr ') ||
        lower == 'dr.' ||
        lower == 'dr';
    return hasDoctorPrefix ? trimmed : 'Dr. $trimmed';
  }

  factory Therapist.fromJson(Map<String, dynamic> json) {
    String _fallbackInitials() {
      final provided = json['initials']?.toString();
      if (provided != null && provided.trim().isNotEmpty) {
        return provided.trim();
      }
      final rawName = json['name']?.toString() ?? '';
      final parts = rawName.split(' ').where((part) => part.isNotEmpty).toList();
      if (parts.length >= 2) {
        return (parts[0][0] + parts[1][0]).toUpperCase();
      }
      if (parts.isNotEmpty) {
        return parts.first[0].toUpperCase();
      }
      return '?';
    }

    return Therapist(
      id: json['id'] as String,
      name: json['name'] as String,
      specialties: json['specialties'] as String,
      location: json['location'] as String,
      address: json['address'] ?? json['location'] ?? '',
      languages: json['languages'] as String,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: (json['ratingCount'] as num?)?.toInt() ?? 0,
      imageUrl: json['imageUrl'] as String?,
      initials: _fallbackInitials(),
      title: json['title'] ?? 'Licensed Counselor',
      centerName: json['centerName'] ?? 'Holistic Mind Center',
      quote: json['quote'] ?? 'Here to help you heal.',
      price: (json['price'] as num?)?.toDouble() ?? 150.0,
    );
  }
}
