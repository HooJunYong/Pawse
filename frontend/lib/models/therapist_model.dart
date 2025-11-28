// Therapist data model for therapist list
class Therapist {
  final String id;
  final String name;
  final String specialties;
  final String location; // State for list view
  final String address; // Full address for detail view
  final String languages;
  final double rating;
  final String imageUrl; // Or initials if no image
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
    required this.imageUrl,
    required this.title,
    required this.centerName,
    required this.quote,
    required this.price,
  });

  factory Therapist.fromJson(Map<String, dynamic> json) {
    return Therapist(
      id: json['id'] as String,
      name: json['name'] as String,
      specialties: json['specialties'] as String,
      location: json['location'] as String,
      address: json['address'] ?? json['location'] ?? '',
      languages: json['languages'] as String,
      rating: (json['rating'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String,
      title: json['title'] ?? 'Licensed Counselor',
      centerName: json['centerName'] ?? 'Holistic Mind Center',
      quote: json['quote'] ?? 'Here to help you heal.',
      price: (json['price'] as num?)?.toDouble() ?? 150.0,
    );
  }
}
