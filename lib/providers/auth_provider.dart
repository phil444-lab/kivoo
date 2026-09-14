import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/item_model.dart';
import '../services/auth_service.dart';
import '../services/authed_http_client.dart';
import '../services/google_auth_service.dart';
import '../services/favorite_service.dart';
import '../services/notification_service.dart';
import '../utils/picked_image.dart';

class AuthProvider extends ChangeNotifier implements AuthSessionDelegate {

  AuthProvider({
    AuthService? authService,
    FavoriteService? favoriteService,
  })  : _authService = authService ?? AuthService(),
        _favoriteService = favoriteService ?? FavoriteService() {
    // Exposer la session au client HTTP central : refresh automatique du
    // token + retry unique sur 401 pour TOUS les services (items,
    // conversations, notifications…), pas seulement les favoris.
    AuthedHttpClient.delegate = this;
    _loadStoredAuth();
  }

  /// Token courant — requis par [AuthSessionDelegate].
  @override
  String? get accessToken => _token;
  final AuthService _authService;
  final FavoriteService _favoriteService;
  final GoogleAuthService _googleAuthService = GoogleAuthService();

  User? _user;
  String? _token;
  String? _refreshToken;
  bool _isLoading = false;
  bool _isInitialized = false;
  final Set<String> _favoriteItemIds = {};
  List<ItemModel> _favoriteItems = [];
  bool _isLoadingFavorites = false;

  /// Rafraîchissement de token en cours : partagé par les appels simultanés
  /// (favoris, notifications…) pour ne pas invalider deux sessions à la fois.
  Future<bool>? _refreshInFlight;

  User? get user => _user;
  String? get token => _token;
  String? get refreshToken => _refreshToken;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _token != null && _user != null;
  bool get isLoadingFavorites => _isLoadingFavorites;
  Set<String> get favoriteItemIds => Set.unmodifiable(_favoriteItemIds);
  List<ItemModel> get favoriteItems => List.unmodifiable(_favoriteItems);

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
        // Restaurer la session : le JWT ne dure que 15 min, or la PWA web
        // restaure le token depuis le stockage local à chaque rechargement.
        // On le rafraîchit donc si besoin, puis on charge les favoris pour
        // que les cœurs soient à jour dès l'ouverture de l'app.
        unawaited(_restoreSession());
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
    _favoriteItems = [];
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
        providerId: googleResult.googleUserId,
        email: googleResult.email,
        name: googleResult.name,
        photo: googleResult.photoUrl,
        // Web : accessToken vérifié par le backend via tokeninfo Google.
        // Mobile : on transmet l'idToken JWT à la place — l'accessToken
        // mobile est émis pour le client OAuth Android (aud différent du
        // client Web) et serait rejeté par la vérification serveur.
        accessToken: kIsWeb ? googleResult.accessToken : null,
        idToken: googleResult.idToken,
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
    // Désenregistrer le token FCM avant de se déconnecter
    try {
      final notificationService = NotificationService();
      final fcmToken = await notificationService.getToken();
      if (fcmToken != null) {
        await notificationService.unregisterToken(fcmToken);
      }
    } catch (e) {
      debugPrint('Erreur lors du désenregistrement du token FCM: $e');
    }

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

  Future<bool> deleteAccount() async {
    if (_token == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await _authService.deleteAccount(_token!);

      if (response['success'] == true) {
        await _clearAuth();
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
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

  /// Restaure la session au démarrage : rafraîchit le token s'il est expiré
  /// puis charge les favoris (l'état local est vide au lancement).
  Future<void> _restoreSession() async {
    await ensureValidToken();
    if (_token != null) {
      await loadFavorites();
    }
  }

  /// Décode localement la date d'expiration (`exp`) d'un JWT.
  /// Retourne null si le token n'est pas un JWT décodable.
  DateTime? _tokenExpiry(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload =
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final map = jsonDecode(payload) as Map<String, dynamic>;
      final exp = map['exp'];
      if (exp is int) {
        return DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Garantit qu'un token d'accès utilisable est disponible, en le rafraîchissant
  /// s'il est expiré (ou expire dans moins de 60 secondes).
  ///
  /// ⚠️ Indispensable sur le web : le JWT ne dure que 15 minutes et la PWA
  /// restaure le token depuis le stockage local à chaque rechargement. Sans
  /// rafraîchissement, tous les appels authentifiés (dont les favoris) échouent
  /// en 401 alors que l'UI se croit encore connectée (cœurs gris, actions
  /// silencieusement ignorées).
  ///
  /// Retourne true si un token (valide ou indécodable) est disponible.
  Future<bool> ensureValidToken() async {
    final token = _token;
    if (token == null) return false;

    final expiry = _tokenExpiry(token);
    // Token illisible : on laisse le serveur trancher (retry sur 401).
    if (expiry == null) return true;

    final now = DateTime.now().toUtc();
    if (expiry.isAfter(now.add(const Duration(seconds: 60)))) return true;

    return _refreshTokensOnce();
  }

  /// Rafraîchissement sérialisé : plusieurs appels simultanés (favoris,
  /// notifications…) partagent le même rafraîchissement. Deux refresh en
  /// parallèle désactiveraient mutuellement leur session côté serveur.
  Future<bool> _refreshTokensOnce() {
    final inFlight = _refreshInFlight;
    if (inFlight != null) return inFlight;

    final future = refreshTokens().whenComplete(() => _refreshInFlight = null);
    _refreshInFlight = future;
    return future;
  }

  /// Exécute une requête authentifiée : rafraîchit le token si nécessaire puis
  /// réessaie une fois après un 401 (session expirée malgré tout).
  Future<T> _withAuthRetry<T>(
    Future<T> Function(String token) request,
    bool Function(T result) shouldRetry,
  ) async {
    if (_token == null) {
      throw StateError('Utilisateur non authentifié');
    }

    await ensureValidToken();

    final token = _token;
    if (token == null) {
      throw StateError('Session expirée');
    }

    final result = await request(token);
    if (!shouldRetry(result)) return result;

    final refreshed = await _refreshTokensOnce();
    final newToken = _token;
    if (!refreshed || newToken == null) return result;

    return request(newToken);
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

  /// Upload la photo de profil (cross-platform mobile + web)
  Future<bool> uploadPhoto(PickedImage image) async {
    if (_token == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final updatedUser = await _authService.uploadPhoto(
        token: _token!,
        bytes: image.bytes,
        fileName: image.name,
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
  bool isFavorite(String itemId) => _favoriteItemIds.contains(itemId);

  /// Ajoute un article aux favoris.
  ///
  /// L'état local (cœur rouge) n'est marqué qu'après confirmation du serveur.
  /// En cas de 401, le token est rafraîchi puis la requête rejouée.
  Future<bool> addToFavorites(String itemId) async {
    if (_token == null) return false;

    _isLoadingFavorites = true;
    notifyListeners();

    try {
      final result = await _withAuthRetry(
        (token) => _favoriteService.addFavorite(token: token, itemId: itemId),
        (r) => r.isUnauthorized,
      );

      if (result.success) {
        _favoriteItemIds.add(itemId);
        notifyListeners();
      }

      _isLoadingFavorites = false;
      notifyListeners();
      return result.success;
    } catch (e) {
      _isLoadingFavorites = false;
      notifyListeners();
      return false;
    }
  }

  /// Retire un article des favoris.
  ///
  /// En cas de 401, le token est rafraîchi puis la requête rejouée.
  Future<bool> removeFromFavorites(String itemId) async {
    if (_token == null) return false;

    _isLoadingFavorites = true;
    notifyListeners();

    try {
      final result = await _withAuthRetry(
        (token) =>
            _favoriteService.removeFavorite(token: token, itemId: itemId),
        (r) => r.isUnauthorized,
      );

      if (result.success) {
        _favoriteItemIds.remove(itemId);
        _favoriteItems.removeWhere((item) => item.id == itemId);
        notifyListeners();
      }

      _isLoadingFavorites = false;
      notifyListeners();
      return result.success;
    } catch (e) {
      _isLoadingFavorites = false;
      notifyListeners();
      return false;
    }
  }

  /// Bascule le statut favori d'un article
  Future<bool> toggleFavorite(String itemId) async {
    if (isFavorite(itemId)) {
      return removeFromFavorites(itemId);
    } else {
      return addToFavorites(itemId);
    }
  }

  /// Charge la liste des favoris de l'utilisateur
  Future<void> loadFavorites() async {
    if (_token == null) return;

    _isLoadingFavorites = true;
    notifyListeners();

    try {
      final result = await _withAuthRetry(
        (token) => _favoriteService.getFavorites(token: token),
        (r) => r.isUnauthorized,
      );

      // On ne vide l'état local que si la liste a réellement été récupérée,
      // sinon une erreur réseau effacerait les cœurs rouges déjà affichés.
      if (result.success) {
        _favoriteItemIds.clear();
        _favoriteItems = [];
        for (final item in result.items!) {
          _favoriteItemIds.add(item.id);
          _favoriteItems.add(item);
        }
      }

      _isLoadingFavorites = false;
      notifyListeners();
    } catch (e) {
      _isLoadingFavorites = false;
      notifyListeners();
    }
  }

  /// Charge la page suivante de favoris
  Future<Map<String, dynamic>?> loadMoreFavorites({required int page}) async {
    if (_token == null) return null;

    try {
      final result = await _withAuthRetry(
        (token) => _favoriteService.getFavorites(
          token: token,
          page: page,
          limit: 20,
        ),
        (r) => r.isUnauthorized,
      );

      if (result.success) {
        for (final item in result.items!) {
          if (!_favoriteItemIds.contains(item.id)) {
            _favoriteItemIds.add(item.id);
            _favoriteItems.add(item);
          }
        }
        notifyListeners();
        return result.pagination;
      }
      return null;
    } catch (e) {
      debugPrint('⚠️ Error loading more favorites: $e');
      return null;
    }
  }

  /// Vérifie le statut favori d'un article (sans charger tous les favoris)
  Future<bool> checkFavoriteStatus(String itemId) async {
    if (_token == null) return false;

    try {
      final result = await _withAuthRetry(
        (token) => _favoriteService.isFavorite(token: token, itemId: itemId),
        (r) => r.isUnauthorized,
      );

      if (!result.success) return false;

      final isFav = result.isFavorite ?? false;
      if (isFav) {
        _favoriteItemIds.add(itemId);
      } else {
        _favoriteItemIds.remove(itemId);
      }
      notifyListeners();
      return isFav;
    } catch (e) {
      return false;
    }
  }
}