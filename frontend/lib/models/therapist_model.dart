// Therapist data model for therapist list
class Therapist {
  final String id;
  final String name;
  final String specialties;
  final String location;
  final String languages;
  final double rating;
  final String imageUrl; // Or initials if no image

  Therapist({
    required this.id,
    required this.name,
    required this.specialties,
    required this.location,
    required this.languages,
    required this.rating,
    required this.imageUrl,
  });

  factory Therapist.fromJson(Map<String, dynamic> json) {
    return Therapist(
      id: json['id'] as String,
      name: json['name'] as String,
      specialties: json['specialties'] as String,
      location: json['location'] as String,
      languages: json['languages'] as String,
      rating: (json['rating'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String,
    );
  }
}
