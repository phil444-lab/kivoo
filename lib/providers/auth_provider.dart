import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/google_auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final GoogleAuthService _googleAuthService = GoogleAuthService();

  User? _user;
  String? _token;
  String? _refreshToken;
  bool _isLoading = false;
  bool _isInitialized = false;

  User? get user => _user;
  String? get token => _token;
  String? get refreshToken => _refreshToken;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _token != null && _user != null;

  AuthProvider() {
    _loadStoredAuth();
  }

  Future<void> _loadStoredAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final refreshToken = prefs.getString('refreshToken');
      final userJson = prefs.getString('user');

      if (token != null && refreshToken != null && userJson != null) {
        _token = token;
        _refreshToken = refreshToken;
        _user = User.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('Error loading stored auth: $e');
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _saveAuth(String token, String refreshToken, User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('refreshToken', refreshToken);
    await prefs.setString('user', jsonEncode(user.toJson()));
  }

  Future<void> _clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('refreshToken');
    await prefs.remove('user');
    _token = null;
    _refreshToken = null;
    _user = null;
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );

      // Pas de stockage des tokens à l'inscription
      // La session est créée uniquement au login
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> login({
    required String identifier,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _authService.login(
        identifier: identifier,
        password: password,
      );

      _token = response.token;
      _refreshToken = response.refreshToken;
      _user = response.user;

      await _saveAuth(response.token, response.refreshToken, response.user);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      final googleResult = await _googleAuthService.signIn();

      if (googleResult == null) {
        // L'utilisateur a annulé
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final response = await _authService.socialLogin(
        provider: 'google',
        providerId: googleResult.idToken,
        email: googleResult.email,
        name: googleResult.name,
        photo: googleResult.photoUrl,
      );

      _token = response.token;
      _refreshToken = response.refreshToken;
      _user = response.user;

      await _saveAuth(response.token, response.refreshToken, response.user);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    if (_token != null) {
      try {
        await _authService.logout(_token!);
      } catch (e) {
        // Ignore logout API errors
      }
    }
    // Déconnexion Google également
    try {
      await _googleAuthService.signOut();
    } catch (e) {
      // Ignore Google sign-out errors
    }
    await _clearAuth();
    notifyListeners();
  }

  Future<bool> refreshTokens() async {
    if (_refreshToken == null) return false;

    try {
      final response = await _authService.refreshToken(_refreshToken!);
      _token = response.token;
      _refreshToken = response.refreshToken;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      await prefs.setString('refreshToken', _refreshToken!);

      notifyListeners();
      return true;
    } catch (e) {
      await _clearAuth();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? currentPassword,
    String? newPassword,
    String? photo,
    Map<String, dynamic>? location,
    Map<String, dynamic>? preferences,
  }) async {
    if (_token == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final updatedUser = await _authService.updateProfile(
        token: _token!,
        name: name,
        email: email,
        phone: phone,
        currentPassword: currentPassword,
        newPassword: newPassword,
        photo: photo,
        location: location,
        preferences: preferences,
      );

      _user = updatedUser;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(updatedUser.toJson()));

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> uploadPhoto(String imagePath) async {
    if (_token == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final updatedUser = await _authService.uploadPhoto(
        token: _token!,
        imagePath: imagePath,
      );

      _user = updatedUser;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(updatedUser.toJson()));

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}
