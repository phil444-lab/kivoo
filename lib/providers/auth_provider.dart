import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/google_auth_service.dart';
import '../services/favorite_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final GoogleAuthService _googleAuthService = GoogleAuthService();

  User? _user;
  String? _token;
  String? _refreshToken;
  bool _isLoading = false;
  bool _isInitialized = false;
  final FavoriteService _favoriteService = FavoriteService();
  final Set<String> _favoriteItemIds = {};
  bool _isLoadingFavorites = false;

  User? get user => _user;
  String? get token => _token;
  String? get refreshToken => _refreshToken;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _token != null && _user != null;
  bool get isLoadingFavorites => _isLoadingFavorites;
  Set<String> get favoriteItemIds => Set.unmodifiable(_favoriteItemIds);

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
        // Charger les favoris dès la restauration de session
        // pour que les boutons favoris soient à jour partout
        unawaited(loadFavorites());
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
    _favoriteItemIds.clear();
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

      // Charger les favoris après connexion
      unawaited(loadFavorites());

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

      // Charger les favoris après connexion Google
      unawaited(loadFavorites());

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

  /// Vérifie si un article est dans les favoris
  bool isFavorite(String itemId) {
    return _favoriteItemIds.contains(itemId);
  }

  /// Ajoute un article aux favoris
  Future<bool> addToFavorites(String itemId) async {
    if (_token == null) return false;

    _isLoadingFavorites = true;
    notifyListeners();

    try {
      final success = await _favoriteService.addFavorite(
        token: _token!,
        itemId: itemId,
      );

      if (success) {
        _favoriteItemIds.add(itemId);
        notifyListeners();
      }

      _isLoadingFavorites = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoadingFavorites = false;
      notifyListeners();
      return false;
    }
  }

  /// Retire un article des favoris
  Future<bool> removeFromFavorites(String itemId) async {
    if (_token == null) return false;

    _isLoadingFavorites = true;
    notifyListeners();

    try {
      final success = await _favoriteService.removeFavorite(
        token: _token!,
        itemId: itemId,
      );

      if (success) {
        _favoriteItemIds.remove(itemId);
        notifyListeners();
      }

      _isLoadingFavorites = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoadingFavorites = false;
      notifyListeners();
      return false;
    }
  }

  /// Bascule le statut favori d'un article
  Future<bool> toggleFavorite(String itemId) async {
    if (isFavorite(itemId)) {
      return await removeFromFavorites(itemId);
    } else {
      return await addToFavorites(itemId);
    }
  }

  /// Charge la liste des favoris de l'utilisateur
  Future<void> loadFavorites() async {
    if (_token == null) return;

    _isLoadingFavorites = true;
    notifyListeners();

    try {
      final favorites = await _favoriteService.getFavorites(token: _token!);
      _favoriteItemIds.clear();
      for (final item in favorites) {
        _favoriteItemIds.add(item.id);
      }

      _isLoadingFavorites = false;
      notifyListeners();
    } catch (e) {
      _isLoadingFavorites = false;
      notifyListeners();
    }
  }

  /// Vérifie le statut favori d'un article (sans charger tous les favoris)
  Future<bool> checkFavoriteStatus(String itemId) async {
    if (_token == null) return false;

    try {
      final isFav = await _favoriteService.isFavorite(
        token: _token!,
        itemId: itemId,
      );

      if (isFav) {
        _favoriteItemIds.add(itemId);
        notifyListeners();
      }

      return isFav;
    } catch (e) {
      return false;
    }
  }
}
