import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../models/item_model.dart';

/// Modèle de profil public d'un vendeur
class PublicSellerProfile {

  const PublicSellerProfile({
    required this.id,
    required this.name,
    this.phone = '',
    this.photo = '',
    this.verified = false,
    this.rating = 0,
    this.ratingCount = 0,
    this.location = '',
    required this.joinedAt,
    this.itemsListed = 0,
    this.itemsSold = 0,
    this.responseRate = 0,
    this.responseTime = '',
  });

  factory PublicSellerProfile.fromJson(Map<String, dynamic> json) {
    // Photo
    String photo = '';
    final rawPhoto = json['photo']?.toString() ?? '';
    if (rawPhoto.startsWith('http://') || rawPhoto.startsWith('https://')) {
      photo = rawPhoto;
    } else if (rawPhoto.isNotEmpty) {
      photo = '${AppConstants.uploadsBaseUrl}/$rawPhoto';
    }

    // Localisation
    String location = '';
    final loc = json['location'];
    if (loc is Map<String, dynamic>) {
      final parts = <String>[];
      if (loc['company'] != null) parts.add(loc['company'].toString());
      if (loc['address'] != null) parts.add(loc['address'].toString());
      if (loc['city'] != null) parts.add(loc['city'].toString());
      location = parts.join(', ');
    } else if (loc != null) {
      location = loc.toString();
    }

    // Stats
    final stats = json['stats'] is Map<String, dynamic>
        ? json['stats'] as Map<String, dynamic>
        : <String, dynamic>{};

    return PublicSellerProfile(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      photo: photo,
      verified: json['verified'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      ratingCount: (json['ratingCount'] as num?)?.toInt() ?? 0,
      location: location,
      joinedAt: DateTime.tryParse(json['joinedAt']?.toString() ?? '') ?? DateTime.now(),
      itemsListed: (stats['itemsListed'] as num?)?.toInt() ?? 0,
      itemsSold: (stats['itemsSold'] as num?)?.toInt() ?? 0,
      responseRate: (stats['responseRate'] as num?)?.toInt() ?? 0,
      responseTime: stats['responseTime']?.toString() ?? '',
    );
  }
  final String id;
  final String name;
  final String phone;
  final String photo;
  final bool verified;
  final double rating;
  final int ratingCount;
  final String location;
  final DateTime joinedAt;
  final int itemsListed;
  final int itemsSold;
  final int responseRate;
  final String responseTime;
}

class PublicProfileService {
  /// Récupère le profil public d'un vendeur
  Future<PublicSellerProfile?> getSellerProfile(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/users/$userId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PublicSellerProfile.fromJson(data['data'] as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('⚠️ Error fetching seller profile: $e');
      return null;
    }
  }

  /// Récupère les annonces actives d'un vendeur
  Future<List<ItemModel>> getSellerItems(String userId, {int page = 1, int limit = 20}) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}/users/$userId/items').replace(
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
          'status': 'active',
        },
      );
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final itemsData = data['data'] as Map<String, dynamic>;
        final itemsList = (itemsData['items'] as List)
            .map((e) => ItemModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return itemsList;
      }
      return [];
    } catch (e) {
      print('⚠️ Error fetching seller items: $e');
      return [];
    }
  }
}