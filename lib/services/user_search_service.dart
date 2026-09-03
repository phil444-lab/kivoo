import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';

class UserSearchService {
  /// Recherche des utilisateurs vendeurs (ayant au moins une annonce active)
  Future<Map<String, dynamic>?> searchSellers({
    required String token,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final uri = Uri.parse('${AppConstants.baseUrl}/users/sellers/search')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('⚠️ Error searching sellers: $e');
      return null;
    }
  }
}
