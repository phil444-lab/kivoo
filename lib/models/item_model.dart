import '../constants.dart';

class ItemModel {
  final String id;
  final String title;
  final String description;
  final String price;
  final String priceType;
  final String priceTypeValue;
  final String location;
  final String condition;
  final String time;
  final String photo;
  final List<String> images;
  final bool verified;
  final String sellerName;
  final String sellerPhoto;
  final double sellerRating;
  final String sellerLocation;
  final String categoryName;
  final String subcategoryName;
  final String brand;
  final String model;
  final String color;
  final int year;
  final int views;
  final int likes;
  final String featureTitle;
  final String featureIcon;
  final bool featured;
  final String categoryId;
  final String subcategoryId;
  final String departmentId;
  final String cityId;
  final String districtId;
  final String featureId;
  final DateTime createdAt;

  const ItemModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.price,
    this.priceType = 'fixed',
    this.priceTypeValue = 'fixed',
    required this.location,
    required this.condition,
    required this.time,
    required this.photo,
    this.images = const [],
    required this.verified,
    this.sellerName = '',
    this.sellerPhoto = '',
    this.sellerRating = 0,
    this.sellerLocation = '',
    this.categoryName = '',
    this.subcategoryName = '',
    this.brand = '',
    this.model = '',
    this.color = '',
    this.year = 0,
    this.views = 0,
    this.likes = 0,
    this.featureTitle = '',
    this.featureIcon = '',
    this.featured = false,
    this.categoryId = '',
    this.subcategoryId = '',
    this.departmentId = '',
    this.cityId = '',
    this.districtId = '',
    this.featureId = '',
    required this.createdAt,
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    // Images
    final rawImages = json['images'];
    List<String> imagesList = [];
    if (rawImages is List) {
      imagesList = rawImages.map((e) => e.toString()).toList();
    }
    String photo = imagesList.isNotEmpty ? imagesList.first : '';

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

    // Type de prix
    const priceTypes = {
      'fixed': 'Prix fixe',
      'negotiable': 'Négociable',
      'rent': 'Location',
      'auction': 'Enchère',
    };
    final priceTypeValue = json['priceType']?.toString() ?? 'fixed';
    final priceType = priceTypes[priceTypeValue] ?? 'Prix fixe';

    // Temps relatif depuis createdAt
    final createdAtRaw = DateTime.tryParse(json['createdAt']?.toString() ?? '');
    final time = _formatRelativeTime(createdAtRaw);

    // Catégorie
    final category = json['category'];
    final categoryName = category is Map<String, dynamic>
        ? (category['name']?.toString() ?? '')
        : '';
    final categoryId = category is Map<String, dynamic>
        ? (category['id']?.toString() ?? '')
        : '';

    // Sous-catégorie
    final subcategory = json['subcategory'];
    final subcategoryName = subcategory is Map<String, dynamic>
        ? (subcategory['name']?.toString() ?? '')
        : '';
    final subcategoryId = subcategory is Map<String, dynamic>
        ? (subcategory['id']?.toString() ?? '')
        : '';

    // Vendeur → nom, photo, rating, vérifié
    final seller = json['seller'];
    final verified = seller is Map<String, dynamic>
        ? (seller['verified'] as bool? ?? false)
        : false;
    final sellerName = seller is Map<String, dynamic>
        ? (seller['name']?.toString() ?? '')
        : '';

    // Photo du vendeur
    String sellerPhoto = '';
    if (seller is Map<String, dynamic>) {
      final sp = seller['photo']?.toString() ?? '';
      if (sp.startsWith('http://') || sp.startsWith('https://')) {
        sellerPhoto = sp;
      } else if (sp.isNotEmpty) {
        sellerPhoto = '${AppConstants.uploadsBaseUrl}/$sp';
      }
    }

    // Rating du vendeur
    final sellerRating = seller is Map<String, dynamic>
        ? ((seller['rating'] as num?)?.toDouble() ?? 0)
        : 0.0;

    // Localisation du vendeur
    String sellerLocation = '';
    if (seller is Map<String, dynamic>) {
      final sl = seller['location'];
      if (sl is Map<String, dynamic>) {
        final locParts = <String>[];
        if (sl['company'] != null) locParts.add(sl['company'].toString());
        if (sl['address'] != null) locParts.add(sl['address'].toString());
        if (sl['city'] != null) locParts.add(sl['city'].toString());
        sellerLocation = locParts.join(', ');
      } else if (sl != null) {
        sellerLocation = sl.toString();
      }
    }

    // Feature
    final feature = json['feature'];
    final featureTitle = feature is Map<String, dynamic>
        ? (feature['title']?.toString() ?? '')
        : '';
    final featureIcon = feature is Map<String, dynamic>
        ? (feature['icon']?.toString() ?? '')
        : '';
    final featureId = feature is Map<String, dynamic>
        ? (feature['id']?.toString() ?? '')
        : '';

    // Département / Ville / Quartier (IDs depuis objets imbriqués ou champs racines)
    final departmentId = dept is Map<String, dynamic>
        ? (dept['id']?.toString() ?? json['departmentId']?.toString() ?? '')
        : (json['departmentId']?.toString() ?? '');
    final cityId = city is Map<String, dynamic>
        ? (city['id']?.toString() ?? json['cityId']?.toString() ?? '')
        : (json['cityId']?.toString() ?? '');
    final districtId = district is Map<String, dynamic>
        ? (district['id']?.toString() ?? json['districtId']?.toString() ?? '')
        : (json['districtId']?.toString() ?? '');

    final createdAt = createdAtRaw ?? DateTime.now();

    return ItemModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: formattedPrice,
      priceType: priceType,
      priceTypeValue: priceTypeValue,
      location: location,
      condition: condition,
      time: time,
      photo: photo,
      images: imagesList,
      verified: verified,
      sellerName: sellerName,
      sellerPhoto: sellerPhoto,
      sellerRating: sellerRating,
      sellerLocation: sellerLocation,
      categoryName: categoryName,
      subcategoryName: subcategoryName,
      brand: json['brand']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      color: json['color']?.toString() ?? '',
      year: (json['year'] as num?)?.toInt() ?? 0,
      views: (json['views'] as num?)?.toInt() ?? 0,
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      featureTitle: featureTitle,
      featureIcon: featureIcon,
      featured: json['featured'] as bool? ?? false,
      categoryId: categoryId,
      subcategoryId: subcategoryId,
      departmentId: departmentId,
      cityId: cityId,
      districtId: districtId,
      featureId: featureId,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'priceType': priceType,
      'priceTypeValue': priceTypeValue,
      'location': location,
      'condition': condition,
      'time': time,
      'photo': photo,
      'images': images,
      'verified': verified,
      'sellerName': sellerName,
      'sellerPhoto': sellerPhoto,
      'sellerRating': sellerRating,
      'sellerLocation': sellerLocation,
      'categoryName': categoryName,
      'subcategoryName': subcategoryName,
      'brand': brand,
      'model': model,
      'color': color,
      'year': year,
      'views': views,
      'likes': likes,
      'featureTitle': featureTitle,
      'featureIcon': featureIcon,
      'featured': featured,
      'categoryId': categoryId,
      'subcategoryId': subcategoryId,
      'departmentId': departmentId,
      'cityId': cityId,
      'districtId': districtId,
      'featureId': featureId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Retourne l'URL complète de la photo principale de l'item
  String get photoUrl {
    if (photo.startsWith('http://') || photo.startsWith('https://')) {
      return photo;
    }
    return '${AppConstants.uploadsBaseUrl}/$photo';
  }

  /// Retourne toutes les URLs complètes des images de l'item
  List<String> get imageUrls {
    final urls = images.map((img) {
      if (img.startsWith('http://') || img.startsWith('https://')) {
        return img;
      }
      return '${AppConstants.uploadsBaseUrl}/$img';
    }).toList();
    return urls.isNotEmpty ? urls : [photoUrl];
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