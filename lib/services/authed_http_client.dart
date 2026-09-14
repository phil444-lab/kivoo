import 'dart:async';
import 'dart:convert' show Encoding;
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// Délégué de session implémenté par [AuthProvider].
///
/// Permet au client HTTP central de rafraîchir le token sans dépendance
/// directe vers le provider (évite les imports circulaires).
abstract class AuthSessionDelegate {
  /// Token d'accès courant (null si déconnecté).
  String? get accessToken;

  /// Rafraîchit le token s'il est expiré (ou proche de l'expirer).
  /// true si un token utilisable est disponible.
  Future<bool> ensureValidToken();

  /// Force un rafraîchissement (après un 401). true en cas de succès.
  Future<bool> refreshTokens();
}

/// Client HTTP central de l'application.
///
/// Toutes les requêtes vers l'API passent par ici, ce qui apporte à **tous**
/// les services (items, conversations, notifications…) les mêmes garanties
/// que les favoris :
///
/// 1. **Timeout explicite** : 20 s pour les requêtes JSON, 60 s pour les
///    uploads (multipart). Un dépassement est converti en
///    [http.ClientException] — les `on http.ClientException` existants des
///    services affichent alors leur message « vérifiez votre connexion »
///    au lieu de laisser un `await` suspendu indéfiniment.
///
/// 2. **Token toujours frais** : avant chaque requête authentifiée, le token
///    est rafraîchi s'il est expiré (délégué à [AuthSessionDelegate]).
///
/// 3. **Retry unique sur 401** : si le serveur répond 401 (session révoquée
///    entre-temps), le token est rafraîchi puis la requête rejouée **une
///    seule fois** — sans boucle infinie. Le refresh est sérialisé côté
///    [AuthProvider] : plusieurs requêtes en 401 simultanées partagent le
///    même rafraîchissement (indispensable car chaque rotation de session
///    désactive la précédente côté serveur).
///
/// Les requêtes sans en-tête `Authorization` (login, endpoints publics) et
/// l'endpoint de refresh lui-même ne sont jamais « rejouées ».
class AuthedHttpClient extends http.BaseClient {
  AuthedHttpClient({http.Client? innerClient})
      : _inner = innerClient ?? http.Client();

  /// Instance partagée : client par défaut de tous les services.
  static final AuthedHttpClient instance = AuthedHttpClient();

  /// Délégué de session, défini par [AuthProvider] à sa création.
  static AuthSessionDelegate? delegate;

  /// Timeout des requêtes JSON classiques.
  static const Duration defaultTimeout = Duration(seconds: 20);

  /// Timeout des uploads (multipart : photos de profil, images d'annonces).
  static const Duration uploadTimeout = Duration(seconds: 60);

  final http.Client _inner;

  bool _isRefreshEndpoint(Uri url) =>
      url.path.contains('/auth/refresh-token');

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final session = delegate;
    final authHeader = request.headers['Authorization'];
    final hasBearer = authHeader != null && authHeader.startsWith('Bearer ');
    final sessionManaged =
        session != null && hasBearer && !_isRefreshEndpoint(request.url);

    // 1. Token frais avant l'envoi (no-op si encore valide).
    if (sessionManaged) {
      try {
        await session.ensureValidToken();
      } catch (_) {
        // Session indéchiffrable : on tente quand même, le 401 éventuel
        // déclenchera le retry ci-dessous.
      }
      final token = session.accessToken;
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
    }

    // 2. Capturer ce qu'il faut pour un éventuel retry : un BaseRequest ne
    //    peut être envoyé qu'une seule fois, on reconstruira une copie.
    final headers = Map<String, String>.of(request.headers);
    Uint8List? bodyBytes;
    Encoding? encoding;
    if (request is http.Request && !request.finalized) {
      bodyBytes = request.bodyBytes;
      encoding = request.encoding;
    }

    final timeout = request is http.MultipartRequest
        ? uploadTimeout
        : defaultTimeout;

    final response = await _sendWithTimeout(request, timeout);

    // 3. Retry unique sur 401.
    if (response.statusCode != 401 || !sessionManaged || bodyBytes == null) {
      return response;
    }

    bool refreshed;
    try {
      refreshed = await session.refreshTokens();
    } catch (_) {
      return response;
    }
    final token = session.accessToken;
    if (!refreshed || token == null) return response;

    // Libérer la connexion de la réponse écartée avant de rejouer.
    await response.stream.drain<void>().catchError((_) {});

    final retry = http.Request(request.method, request.url)
      ..followRedirects = request.followRedirects
      ..maxRedirects = request.maxRedirects
      ..persistentConnection = request.persistentConnection
      ..headers.addAll(headers)
      ..headers['Authorization'] = 'Bearer $token';
    if (encoding != null) retry.encoding = encoding;
    retry.bodyBytes = bodyBytes;

    return _sendWithTimeout(retry, timeout);
  }

  Future<http.StreamedResponse> _sendWithTimeout(
    http.BaseRequest request,
    Duration timeout,
  ) async {
    try {
      return await _inner.send(request).timeout(timeout);
    } on TimeoutException {
      // Converti en ClientException pour réutiliser les gestionnaires
      // `on http.ClientException` déjà présents dans chaque service.
      throw http.ClientException(
        "Le serveur n'a pas répondu dans le délai imparti ($timeout). "
        'Vérifiez votre connexion internet.',
        request.url,
      );
    }
  }
}
