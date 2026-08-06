import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../models/feature_card_model.dart';

class FeatureCardService {
  Future<List<FeatureCardModel>> getFeaturedOptions() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/featured'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> list = data['data'] as List<dynamic>;
        return list
            .map((e) => FeatureCardModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('⚠️ Error fetching featured options: $e');
      return [];
    }
  }
}
