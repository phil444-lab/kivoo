import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
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
    String? accessToken,
    String? idToken,
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
          'accessToken': accessToken,
          'idToken': idToken,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return AuthResponse.fromJson(responseData);
      } else {
        throw Exception(responseData['message'] ?? 'Social login failed');
      }
    } on http.ClientException {
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
    } on http.ClientException {
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
    } on http.ClientException {
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
    } on http.ClientException {
      throw Exception('Impossible de se connecter au serveur. Vérifiez votre connexion internet.');
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<User> updateProfile({
    required String token,
    String? name,
    String? email,
    String? phone,
    String? currentPassword,
    String? newPassword,
    String? photo,
    Map<String, dynamic>? location,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      final body = <String, dynamic>{
        if (name != null) 'name': name,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (photo != null) 'photo': photo,
        if (location != null) 'location': location,
        if (preferences != null) 'preferences': preferences,
        if (currentPassword != null) 'currentPassword': currentPassword,
        if (newPassword != null) 'newPassword': newPassword,
      };

      print('📤 Update Profile Request:');
      print('URL: ${AppConstants.baseUrl}/users/me');
      print('Body: ${jsonEncode(body)}');
      print('Token: $token');

      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/users/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      print('📥 Update Profile Response:');
      print('Status Code: ${response.statusCode}');
      print('Headers: ${response.headers}');
      print('Body: ${response.body}');

      try {
        final responseData = jsonDecode(response.body);
        print('Parsed Response Data: $responseData');

        if (response.statusCode == 200 && responseData['success'] == true) {
          return User.fromJson(responseData['data']);
        } else {
          throw Exception(responseData['message'] ?? 'Update profile failed');
        }
      } catch (e) {
        print('❌ JSON Parse Error: $e');
        throw Exception('Erreur de parsing de la réponse serveur: ${response.body.substring(0, min(100, response.body.length))}');
      }
    } on http.ClientException catch (e) {
      print('❌ Client Exception: $e');
      throw Exception('Impossible de se connecter au serveur. Vérifiez votre connexion internet.');
    } catch (e) {
      print('❌ General Exception: $e');
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Upload la photo de profil (cross-platform mobile + web : bytes)
  Future<User> uploadPhoto({
    required String token,
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstants.baseUrl}${AppConstants.uploadPhotoEndpoint}'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        http.MultipartFile.fromBytes('photo', bytes, filename: fileName),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return User.fromJson(responseData['data']);
      } else {
        throw Exception(responseData['message'] ?? 'Upload photo failed');
      }
    } on http.ClientException {
      throw Exception('Impossible de se connecter au serveur. Vérifiez votre connexion internet.');
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<Map<String, dynamic>> deleteAccount(String token) async {
    try {
      final response = await http.delete(
        Uri.parse('${AppConstants.baseUrl}/users/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        return responseData;
      } else {
        throw Exception(responseData['message'] ?? 'Delete account failed');
      }
    } on http.ClientException {
      throw Exception('Impossible de se connecter au serveur. Vérifiez votre connexion internet.');
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
}
