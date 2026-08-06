import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../models/category_model.dart';

class CategoryService {
  Future<List<CategoryModel>> getSubCategories(String parentId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/categories/$parentId/subcategories'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> list = data['data'] as List<dynamic>;
        return list
            .map((c) => CategoryModel.fromJson(c as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('⚠️ Error fetching subcategories: $e');
      return [];
    }
  }

  Future<List<CategoryModel>> getParentCategories() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/categories'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> list = data['data'] as List<dynamic>;
        return list
            .map((c) => CategoryModel.fromJson(c as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('⚠️ Error fetching categories: $e');
      return [];
    }
  }
}
