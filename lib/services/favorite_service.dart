import 'dart:convert';
import 'package:http/http.dart' as http;
import 'authed_http_client.dart';
import '../constants.dart';
import '../models/item_model.dart';

/// Résultat d'une opération d'ajout / retrait / vérification d'un favori.
///
/// Expose le code HTTP afin que `AuthProvider` puisse détecter une session
/// expirée (401) et rafraîchir le token avant de réessayer.
class FavoriteResult {
  const FavoriteResult({
    required this.success,
    required this.statusCode,
    this.isFavorite,
  });

  /// L'opération a-t-elle réussi (côté serveur) ?
  final bool success;

  /// Code HTTP renvoyé par l'API (-1 si la requête n'a pas abouti).
  final int statusCode;

  /// État du favori renvoyé par l'API, si connu.
  final bool? isFavorite;

  /// La session a expiré : il faut rafraîchir le token puis réessayer.
  bool get isUnauthorized => statusCode == 401;
}

/// Résultat du chargement de la liste paginée des favoris.
class FavoritesListResult {
  const FavoritesListResult({
    required this.statusCode,
    this.items,
    this.pagination,
  });

  final int statusCode;
  final List<ItemModel>? items;
  final Map<String, dynamic>? pagination;

  bool get success => items != null;
  bool get isUnauthorized => statusCode == 401;
}

/// Erreur réseau (aucune réponse HTTP reçue).
const int _noResponseStatusCode = -1;

class FavoriteService {
  /// [client] permet d'injecter un client HTTP en test
  /// (`MockClient` de `package:http/testing.dart`).
  FavoriteService({http.Client? client}) : _client = client ?? AuthedHttpClient.instance;

  final http.Client _client;

  /// Récupère les favoris de l'utilisateur connecté
  /// Retourne les items + la pagination, ou un résultat sans items en cas
  /// d'échec (le code HTTP permet de détecter une session expirée).
  Future<FavoritesListResult> getFavorites({
    required String token,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}/favorites').replace(
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );

      final response = await _client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final dataMap = data['data'] as Map<String, dynamic>;
        final favorites = dataMap['favorites'] as List;
        final pagination = dataMap['pagination'] as Map<String, dynamic>;

        final items = favorites
            .map((fav) => ItemModel.fromJson(fav['item'] as Map<String, dynamic>))
            .toList();

        return FavoritesListResult(
          statusCode: response.statusCode,
          items: items,
          pagination: pagination,
        );
      }

      return FavoritesListResult(statusCode: response.statusCode);
    } catch (e) {
      print('⚠️ Error fetching favorites: $e');
      return const FavoritesListResult(statusCode: _noResponseStatusCode);
    }
  }

  /// Ajoute un article aux favoris.
  ///
  /// Succès si 201 (créé), 200 (déjà en favoris — API idempotente) ou
  /// 409 (conflit d'unicité : l'annonce est déjà en favoris).
  Future<FavoriteResult> addFavorite({
    required String token,
    required String itemId,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('${AppConstants.baseUrl}/favorites/$itemId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return FavoriteResult(
        success: response.statusCode == 201 ||
            response.statusCode == 200 ||
            response.statusCode == 409,
        statusCode: response.statusCode,
        isFavorite: true,
      );
    } catch (e) {
      print('⚠️ Error adding favorite: $e');
      return const FavoriteResult(
        success: false,
        statusCode: _noResponseStatusCode,
      );
    }
  }

  /// Retire un article des favoris.
  ///
  /// Succès si 200 (retiré ou déjà absent — API idempotente), 204 (no content)
  /// ou 404 (le favori n'existait plus).
  Future<FavoriteResult> removeFavorite({
    required String token,
    required String itemId,
  }) async {
    try {
      final response = await _client.delete(
        Uri.parse('${AppConstants.baseUrl}/favorites/$itemId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return FavoriteResult(
        success: response.statusCode == 200 ||
            response.statusCode == 204 ||
            response.statusCode == 404,
        statusCode: response.statusCode,
        isFavorite: false,
      );
    } catch (e) {
      print('⚠️ Error removing favorite: $e');
      return const FavoriteResult(
        success: false,
        statusCode: _noResponseStatusCode,
      );
    }
  }

  /// Vérifie si un article est dans les favoris
  Future<FavoriteResult> isFavorite({
    required String token,
    required String itemId,
  }) async {
    try {
      final response = await _client.get(
        Uri.parse('${AppConstants.baseUrl}/favorites/check/$itemId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final isFav = data['data']['isFavorite'] as bool? ?? false;
        return FavoriteResult(
          success: true,
          statusCode: response.statusCode,
          isFavorite: isFav,
        );
      }

      return FavoriteResult(success: false, statusCode: response.statusCode);
    } catch (e) {
      print('⚠️ Error checking favorite: $e');
      return const FavoriteResult(
        success: false,
        statusCode: _noResponseStatusCode,
      );
    }
  }
}