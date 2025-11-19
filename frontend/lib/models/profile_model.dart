/// Profile model representing user profile information
class Profile {
  final String userId;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String? profilePicture;
  final String? initials;
  final String? joinedDate;

  Profile({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    this.profilePicture,
    this.initials,
    this.joinedDate,
  });

  /// Create a Profile from JSON
  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      userId: json['user_id'] ?? '',
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      profilePicture: json['profile_picture'],
      initials: json['initials'],
      joinedDate: json['joined_date'],
    );
  }

  /// Convert Profile to JSON
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber,
      if (profilePicture != null) 'profile_picture': profilePicture,
      if (initials != null) 'initials': initials,
      if (joinedDate != null) 'joined_date': joinedDate,
    };
  }

  /// Create a copy of Profile with updated fields
  Profile copyWith({
    String? userId,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? profilePicture,
    String? initials,
    String? joinedDate,
  }) {
    return Profile(
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profilePicture: profilePicture ?? this.profilePicture,
      initials: initials ?? this.initials,
      joinedDate: joinedDate ?? this.joinedDate,
    );
  }
}
