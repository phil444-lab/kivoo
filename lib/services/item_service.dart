import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../constants.dart';
import '../models/item_model.dart';

class ItemService {
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
  /// Crée un article avec photos (multipart/form-data)
  Future<Map<String, dynamic>?> createItem({
    required String token,
    required String title,
    required String description,
    required double price,
    required String categoryId,
    String? subcategoryId,
    required List<File> images,
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
      final request = http.MultipartRequest('POST', uri);

      // Headers
      request.headers['Authorization'] = 'Bearer $token';

      // Champs texte
      request.fields['title'] = title;
      request.fields['description'] = description;
      request.fields['price'] = price.toString();
      request.fields['categoryId'] = categoryId;
      if (subcategoryId != null) request.fields['subcategoryId'] = subcategoryId;
      if (brand != null) request.fields['brand'] = brand;
      if (model != null) request.fields['model'] = model;
      if (year != null) request.fields['year'] = year.toString();
      if (color != null) request.fields['color'] = color;
      if (condition != null) request.fields['condition'] = condition;
      if (departmentId != null) request.fields['departmentId'] = departmentId;
      if (cityId != null) request.fields['cityId'] = cityId;
      if (districtId != null) request.fields['districtId'] = districtId;
      if (featureId != null) request.fields['featureId'] = featureId;

      // Fichiers images
      for (final image in images) {
        final mimeType = lookupMimeType(image.path) ?? 'image/jpeg';
        request.files.add(
          await http.MultipartFile.fromPath(
            'images',
            image.path,
            contentType: MediaType.parse(mimeType),
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

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