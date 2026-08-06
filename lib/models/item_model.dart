import 'dart:convert';
import '../constants.dart';

class ItemModel {
  final String id;
  final String title;
  final String price;
  final String location;
  final String condition;
  final String time;
  final String photo;
  final bool verified;
  final String categoryName;
  final DateTime createdAt;

  const ItemModel({
    required this.id,
    required this.title,
    required this.price,
    required this.location,
    required this.condition,
    required this.time,
    required this.photo,
    required this.verified,
    this.categoryName = '',
    required this.createdAt,
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    // Images
    String photo = '';
    final images = json['images'];
    if (images is List && images.isNotEmpty) {
      photo = images.first.toString();
    }

    // Localisation (department, city, district imbriqués)
    String location = '';
    final dept = json['department'];
    final city = json['city'];
    final district = json['district'];
    if (city is Map<String, dynamic>) {
      location = city['name']?.toString() ?? '';
    }
    if (dept is Map<String, dynamic>) {
      final deptName = dept['name']?.toString() ?? '';
      location = location.isEmpty ? deptName : '$deptName, $location';
    }
    if (district is Map<String, dynamic>) {
      final districtName = district['name']?.toString() ?? '';
      location = location.isEmpty ? districtName : '$districtName, $location';
    }
    if (location.isEmpty) location = 'Localisation inconnue';

    // Condition (enum API → libellé français)
    const conditions = {
      'new': 'Neuf',
      'like_new': 'Comme neuf',
      'good': 'Bon état',
      'fair': 'État correct',
      'used': 'Occasion',
    };
    final condition = conditions[json['condition']?.toString()] ?? 'Bon état';

    // Prix (double → FCFA formaté)
    final price = (json['price'] as num?)?.toDouble() ?? 0;
    final formattedPrice = _formatPrice(price);

    // Temps relatif depuis createdAt
    final createdAtRaw = DateTime.tryParse(json['createdAt']?.toString() ?? '');
    final time = _formatRelativeTime(createdAtRaw);

    // Catégorie
    final category = json['category'];
    final categoryName = category is Map<String, dynamic>
        ? (category['name']?.toString() ?? '')
        : '';

    // Vérifié → vient du vendeur
    final seller = json['seller'];
    final verified = seller is Map<String, dynamic>
        ? (seller['verified'] as bool? ?? false)
        : false;

    final createdAt = createdAtRaw ?? DateTime.now();

    return ItemModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      price: formattedPrice,
      location: location,
      condition: condition,
      time: time,
      photo: photo,
      verified: verified,
      categoryName: categoryName,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'location': location,
      'condition': condition,
      'time': time,
      'photo': photo,
      'verified': verified,
      'categoryName': categoryName,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Retourne l'URL complète de la photo de l'item
  String get photoUrl {
    // Si c'est déjà une URL complète (http/https), la retourner telle quelle
    if (photo.startsWith('http://') || photo.startsWith('https://')) {
      return photo;
    }
    // Sinon, c'est un nom de fichier, construire l'URL
    return '${AppConstants.uploadsBaseUrl}/$photo';
  }

  /// Formate un prix numérique en chaîne FCFA avec séparateurs de milliers.
  static String _formatPrice(double price) {
    final units = price.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < units.length; i++) {
      if (i > 0 && (units.length - i) % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(units[i]);
    }
    return '$buffer FCFA';
  }

  /// Calcule un temps relatif lisible ("Il y a 2h", "Il y a 3j"...).
  static String _formatRelativeTime(DateTime? date) {
    if (date == null) return 'Récemment';
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return "À l'instant";
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
    if (diff.inDays < 30) return 'Il y a ${diff.inDays ~/ 7} sem.';
    if (diff.inDays < 365) return 'Il y a ${diff.inDays ~/ 30} mois';
    return 'Il y a ${diff.inDays ~/ 365} an${diff.inDays ~/ 365 > 1 ? 's' : ''}';
  }
}