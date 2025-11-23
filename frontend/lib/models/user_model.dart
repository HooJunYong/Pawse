/// User model representing a user in the system
class User {
  final String userId;
  final String email;
  final String fullName;

  User({
    required this.userId,
    required this.email,
    required this.fullName,
  });

  /// Create a User from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
    );
  }

  /// Convert User to JSON
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'email': email,
      'full_name': fullName,
    };
  }
}

/// Login response model
class LoginResponse {
  final String message;
  final String userId;
  final String email;

  LoginResponse({
    required this.message,
    required this.userId,
    required this.email,
  });

  /// Create a LoginResponse from JSON
  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      message: json['message'] ?? '',
      userId: json['user_id'] ?? '',
      email: json['email'] ?? '',
    );
  }
}
