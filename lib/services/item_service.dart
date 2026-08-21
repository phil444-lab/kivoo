import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../models/item_model.dart';

class ItemService {
  /// Récupère les annonces de l'utilisateur connecté
  Future<List<ItemModel>> getMyItems({required String token, int page = 1, int limit = 50}) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}/items/mine').replace(
        queryParameters: {'page': page.toString(), 'limit': limit.toString()},
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
        final itemsData = data['data'] as Map<String, dynamic>;
        final itemsList = (itemsData['items'] as List)
            .map((e) => ItemModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return itemsList;
      }
      return [];
    } catch (e) {
      print('⚠️ Error fetching my items: $e');
      return [];
    }
  }

  /// Récupère un article par son ID (avec tous les détails)
  Future<ItemModel?> getItemById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/items/$id'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ItemModel.fromJson(data['data'] as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('⚠️ Error fetching item by id: $e');
      return null;
    }
  }

  /// Récupère les articles tendances (triés par nombre de vues)
  Future<List<ItemModel>> getTrendingItems({int limit = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/items/trending?limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> list = data['data'] as List<dynamic>;
        return list
            .map((e) => ItemModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('⚠️ Error fetching trending items: $e');
      return [];
    }
  }

  /// Récupère les items par catégorie/sous-catégorie avec filtres optionnels
  Future<Map<String, dynamic>?> getItems({
    String? categoryId,
    String? subcategoryId,
    String? search,
    String? condition,
    double? minPrice,
    double? maxPrice,
    String sort = 'newest',
    int page = 1,
    int limit = 20,
    String? departmentId,
    String? cityId,
    String? districtId,
    String? color,
    String? brand,
    String? priceType,
    String? featureId,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        'sort': sort,
      };

      if (categoryId != null && categoryId.isNotEmpty) {
        queryParams['category'] = categoryId;
      }
      if (subcategoryId != null && subcategoryId.isNotEmpty) {
        queryParams['subcategory'] = subcategoryId;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (condition != null && condition.isNotEmpty) {
        queryParams['condition'] = condition;
      }
      if (minPrice != null) {
        queryParams['minPrice'] = minPrice.toString();
      }
      if (maxPrice != null) {
        queryParams['maxPrice'] = maxPrice.toString();
      }
      if (departmentId != null && departmentId.isNotEmpty) {
        queryParams['department'] = departmentId;
      }
      if (cityId != null && cityId.isNotEmpty) {
        queryParams['city'] = cityId;
      }
      if (districtId != null && districtId.isNotEmpty) {
        queryParams['district'] = districtId;
      }
      if (color != null && color.isNotEmpty) {
        queryParams['color'] = color;
      }
      if (brand != null && brand.isNotEmpty) {
        queryParams['brand'] = brand;
      }
      if (priceType != null && priceType.isNotEmpty) {
        queryParams['priceType'] = priceType;
      }
      if (featureId != null && featureId.isNotEmpty) {
        queryParams['feature'] = featureId;
      }

      final uri = Uri.parse('${AppConstants.baseUrl}/items').replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print('⚠️ Error fetching items: $e');
      return null;
    }
  }

  /// Met à jour un article existant (en JSON avec les URLs Cloudinary)
  Future<Map<String, dynamic>?> updateItem({
    required String token,
    required String itemId,
    String? title,
    String? description,
    double? price,
    String? priceType,
    String? categoryId,
    String? subcategoryId,
    List<String>? images,
    String? brand,
    String? model,
    int? year,
    String? color,
    String? condition,
    String? departmentId,
    String? cityId,
    String? districtId,
    String? featureId,
  }) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}/items/$itemId');

      // Envoyer les données en JSON avec les URLs Cloudinary
      final body = <String, dynamic>{};
      if (title != null) body['title'] = title;
      if (description != null) body['description'] = description;
      if (price != null) body['price'] = price;
      if (priceType != null) body['priceType'] = priceType;
      if (categoryId != null) body['categoryId'] = categoryId;
      if (subcategoryId != null) body['subcategoryId'] = subcategoryId;
      if (brand != null) body['brand'] = brand;
      if (model != null) body['model'] = model;
      if (year != null) body['year'] = year;
      if (color != null) body['color'] = color;
      if (condition != null) body['condition'] = condition;
      if (departmentId != null) body['departmentId'] = departmentId;
      if (cityId != null) body['cityId'] = cityId;
      if (districtId != null) body['districtId'] = districtId;
      if (featureId != null) body['featureId'] = featureId;
      if (images != null && images.isNotEmpty) body['images'] = images;

      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] as Map<String, dynamic>?;
      }
      print('⚠️ Error updating item: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      print('⚠️ Error updating item: $e');
      return null;
    }
  }

  /// Désactive une annonce (passe le statut de 'active' à 'pending')
  Future<bool> deactivateItem({required String token, required String itemId}) async {
    try {
      final response = await http.patch(
        Uri.parse('${AppConstants.baseUrl}/items/$itemId/deactivate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      print('⚠️ Error deactivating item: ${response.statusCode} - ${response.body}');
      return false;
    } catch (e) {
      print('⚠️ Error deactivating item: $e');
      return false;
    }
  }

  /// Réactive une annonce (passe le statut de 'pending' à 'active')
  Future<bool> activateItem({required String token, required String itemId}) async {
    try {
      final response = await http.patch(
        Uri.parse('${AppConstants.baseUrl}/items/$itemId/activate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('⚠️ Error activating item: $e');
      return false;
    }
  }

  /// Supprime une annonce et tous les éléments associés (conversations, avis, favoris)
  Future<bool> deleteItem({required String token, required String itemId}) async {
    try {
      final response = await http.delete(
        Uri.parse('${AppConstants.baseUrl}/items/$itemId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print('⚠️ Error deleting item: $e');
      return false;
    }
  }

  /// Crée un article avec les URLs Cloudinary (JSON)
  Future<Map<String, dynamic>?> createItem({
    required String token,
    required String title,
    required String description,
    required double price,
    String? priceType,
    required String categoryId,
    String? subcategoryId,
    required List<String> images,
    String? brand,
    String? model,
    int? year,
    String? color,
    String? condition,
    String? departmentId,
    String? cityId,
    String? districtId,
    String? featureId,
  }) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}/items');

      // Corps de la requête JSON
      final body = <String, dynamic>{
        'title': title,
        'description': description,
        'price': price,
        'categoryId': categoryId,
        'images': images,
      };
      if (priceType != null) body['priceType'] = priceType;
      if (subcategoryId != null) body['subcategoryId'] = subcategoryId;
      if (brand != null) body['brand'] = brand;
      if (model != null) body['model'] = model;
      if (year != null) body['year'] = year;
      if (color != null) body['color'] = color;
      if (condition != null) body['condition'] = condition;
      if (departmentId != null) body['departmentId'] = departmentId;
      if (cityId != null) body['cityId'] = cityId;
      if (districtId != null) body['districtId'] = districtId;
      if (featureId != null) body['featureId'] = featureId;

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['data'] as Map<String, dynamic>?;
      } else {
        print('⚠️ Error creating item: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('⚠️ Error creating item: $e');
      return null;
    }
  }
}