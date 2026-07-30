import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../models/user_model.dart';

class AuthService {
  Future<AuthResponse> socialLogin({
    required String provider,
    required String providerId,
    required String email,
    required String name,
    String? photo,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.socialLoginEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'provider': provider,
          'providerId': providerId,
          'email': email,
          'name': name,
          'photo': photo,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return AuthResponse.fromJson(responseData);
      } else {
        throw Exception(responseData['message'] ?? 'Social login failed');
      }
    } on http.ClientException catch (e) {
      throw Exception('Impossible de se connecter au serveur. Vérifiez votre connexion internet.');
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> logout(String token) async {
    try {
      await http.post(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.logoutEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      // Ignore logout errors
    }
  }

  Future<AuthResponse> refreshToken(String refreshToken) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.refreshTokenEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $refreshToken',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return AuthResponse(
          success: true,
          user: User.fromJson({}),
          token: responseData['data']['token'] as String,
          refreshToken: responseData['data']['refreshToken'] as String,
        );
      } else {
        throw Exception(responseData['message'] ?? 'Token refresh failed');
      }
    } on http.ClientException catch (e) {
      throw Exception('Impossible de se connecter au serveur.');
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<AuthResponse> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.registerEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201 && responseData['success'] == true) {
        return AuthResponse.fromJson(responseData);
      } else {
        throw Exception(responseData['message'] ?? 'Registration failed');
      }
    } on http.ClientException catch (e) {
      throw Exception('Impossible de se connecter au serveur. Vérifiez votre connexion internet.');
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<AuthResponse> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}${AppConstants.loginEndpoint}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'identifier': identifier,
          'password': password,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return AuthResponse.fromJson(responseData);
      } else {
        throw Exception(responseData['message'] ?? 'Login failed');
      }
    } on http.ClientException catch (e) {
      throw Exception('Impossible de se connecter au serveur. Vérifiez votre connexion internet.');
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
}