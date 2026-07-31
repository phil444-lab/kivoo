import '../../constants.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? photo;
  final bool verified;
  final double rating;
  final int ratingCount;
  final Map<String, dynamic>? location;
  final DateTime joinedAt;
  final DateTime? lastLogin;
  final bool isActive;
  final Map<String, dynamic> preferences;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.photo,
    this.verified = false,
    this.rating = 0.0,
    this.ratingCount = 0,
    this.location,
    required this.joinedAt,
    this.lastLogin,
    this.isActive = true,
    this.preferences = const {},
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      photo: json['photo'] as String?,
      verified: json['verified'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: json['ratingCount'] as int? ?? 0,
      location: json['location'] as Map<String, dynamic>?,
      joinedAt: DateTime.parse((json['joinedAt'] as String).replaceFirst(' ', 'T')),
      lastLogin: json['lastLogin'] != null ? DateTime.parse((json['lastLogin'] as String).replaceFirst(' ', 'T')) : null,
      isActive: json['isActive'] as bool? ?? true,
      preferences: json['preferences'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'photo': photo,
      'verified': verified,
      'rating': rating,
      'ratingCount': ratingCount,
      'location': location,
      'joinedAt': joinedAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      'isActive': isActive,
      'preferences': preferences,
    };
  }

  /// Retourne l'URL complète de la photo de profil
  String? get photoUrl {
    if (photo == null || photo!.isEmpty) return null;
    // Si c'est déjà une URL complète (http/https), la retourner telle quelle
    if (photo!.startsWith('http://') || photo!.startsWith('https://')) {
      return photo;
    }
    // Sinon, c'est un nom de fichier, construire l'URL
    return '${AppConstants.uploadsBaseUrl}/$photo';
  }
}

class AuthResponse {
  final bool success;
  final User user;
  final String token;
  final String refreshToken;

  AuthResponse({
    required this.success,
    required this.user,
    required this.token,
    required this.refreshToken,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] as bool,
      user: User.fromJson(json['data']['user'] as Map<String, dynamic>),
      token: json['data']['token'] as String,
      refreshToken: json['data']['refreshToken'] as String,
    );
  }
}