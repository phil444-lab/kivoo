import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../models/location_model.dart';

class LocationService {
  Future<List<Country>> getCountries() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/locations/countries'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> countriesJson = data['data'] as List<dynamic>;
        return countriesJson
            .map((c) => Country.fromJson(c as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('⚠️ Error fetching countries: $e');
      return [];
    }
  }

  Future<List<Department>> getDepartments(String countryId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/locations/countries/$countryId/departments'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> departmentsJson = data['data'] as List<dynamic>;
        return departmentsJson
            .map((d) => Department.fromJson(d as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('⚠️ Error fetching departments: $e');
      return [];
    }
  }

  Future<List<City>> getCities(String departmentId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/locations/departments/$departmentId/cities'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> citiesJson = data['data'] as List<dynamic>;
        return citiesJson
            .map((c) => City.fromJson(c as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('⚠️ Error fetching cities: $e');
      return [];
    }
  }

  Future<List<District>> getDistricts(String cityId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/locations/cities/$cityId/districts'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> districtsJson = data['data'] as List<dynamic>;
        return districtsJson
            .map((d) => District.fromJson(d as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('⚠️ Error fetching districts: $e');
      return [];
    }
  }
}