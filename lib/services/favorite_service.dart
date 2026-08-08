import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../models/item_model.dart';

class FavoriteService {
  /// Récupère les favoris de l'utilisateur connecté
  Future<List<ItemModel>> getFavorites({
    required String token,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}/favorites').replace(
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final favorites = data['data']['favorites'] as List;
        
        return favorites
            .map((fav) => ItemModel.fromJson(fav['item'] as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('⚠️ Error fetching favorites: $e');
      return [];
    }
  }

  /// Ajoute un article aux favoris
  Future<bool> addFavorite({
    required String token,
    required String itemId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/favorites/$itemId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 201;
    } catch (e) {
      print('⚠️ Error adding favorite: $e');
      return false;
    }
  }

  /// Retire un article des favoris
  Future<bool> removeFavorite({
    required String token,
    required String itemId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('${AppConstants.baseUrl}/favorites/$itemId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('⚠️ Error removing favorite: $e');
      return false;
    }
  }

  /// Vérifie si un article est dans les favoris
  Future<bool> isFavorite({
    required String token,
    required String itemId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/favorites/check/$itemId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']['isFavorite'] as bool;
      }
      return false;
    } catch (e) {
      print('⚠️ Error checking favorite: $e');
      return false;
    }
  }
}