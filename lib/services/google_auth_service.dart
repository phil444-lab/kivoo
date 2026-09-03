import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: '329144921089-3lkhb9dv7umhbtnolfjitd1fvaar0q1t.apps.googleusercontent.com',
  );

  /// Déclenche la connexion Google et retourne l'idToken et les infos
  /// utilisateur.
  ///
  /// Retourne `null` si l'utilisateur annule (popup fermée, consentement
  /// refusé, etc.) : dans ce cas aucun message d'erreur ne doit s'afficher
  /// dans les écrans de connexion / inscription.
  Future<GoogleSignInResult?> signIn() async {
    try {
      final account = await _googleSignIn.signIn();

      if (account == null) {
        // L'utilisateur a annulé la connexion (comportement mobile)
        return null;
      }

      final auth = await account.authentication;

      final idToken = auth.idToken;
      // Sur le web, le flux `signIn()` de google_sign_in_web ne fournit pas
      // d'idToken (profil synthétisé via la People API). On s'appuie alors
      // sur l'accessToken + l'ID Google du compte (vérifié côté serveur).
      final accessToken = auth.accessToken;

      if ((idToken == null || idToken.isEmpty) &&
          (accessToken == null || accessToken.isEmpty)) {
        throw Exception('Impossible d\'obtenir les tokens Google');
      }

      return GoogleSignInResult(
        googleUserId: account.id,
        idToken: idToken,
        accessToken: accessToken,
        email: account.email,
        name: account.displayName ?? account.email.split('@').first,
        photoUrl: account.photoUrl,
      );
    } catch (e) {
      // Sur le web (Google Identity Services), fermer la popup lève une
      // exception (`popup_closed`, `sign_in_canceled`...) au lieu de
      // retourner null comme sur mobile. On la traite comme une annulation
      // → silence total, aucun message affiché.
      if (isUserCancellation(e)) {
        if (kDebugMode) {
          debugPrint('Google Sign-In : annulé par l\'utilisateur');
        }
        return null;
      }

      if (kDebugMode) {
        debugPrint('Google Sign-In error: $e');
      }

      // Message court et compréhensible — jamais de détail technique
      // (JSON brut, code interne, stacktrace) sur les écrans d'auth.
      throw Exception(friendlyGoogleError(e));
    }
  }

  /// Déconnexion Google
  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  /// Détecte les erreurs qui correspondent à une annulation utilisateur.
  ///
  /// Couvre tous les libellés connus selon la plateforme :
  ///  - web (Google Identity Services) : `popup_closed`, `popup_closed_by_user`,
  ///    `sign_in_canceled`, `access_denied`
  ///  - Android : code 12501 (SIGN_IN_CANCELLED)
  ///  - iOS : `sign_in_canceled`
  static bool isUserCancellation(Object error) {
    final text = error.toString().toLowerCase();
    const hints = [
      'popup_closed',
      'sign_in_canceled',
      'sign_in_cancelled',
      'access_denied',
      'canceled',
      'cancelled',
      '12501', // Android : SIGN_IN_CANCELLED
    ];
    return hints.any(text.contains);
  }

  /// Convertit une erreur Google en message utilisateur court et clair.
  static String friendlyGoogleError(Object error) {
    final text = error.toString().toLowerCase();

    // People API désactivée sur le projet Google Cloud, OAuth mal configuré,
    // origine non autorisée, etc.
    if (text.contains('people api') ||
        text.contains('people.googleapis') ||
        text.contains('permission_denied') ||
        text.contains('idpiframe') ||
        (text.contains('origin') && text.contains('not allowed'))) {
      return 'Connexion Google temporairement indisponible. '
          'Veuillez réessayer dans quelques minutes.';
    }

    if (text.contains('clientexception') ||
        text.contains('socketexception') ||
        text.contains('failed host lookup') ||
        text.contains('network')) {
      return 'Impossible de se connecter à Google. '
          'Vérifiez votre connexion internet.';
    }

    return 'Une erreur est survenue lors de la connexion avec Google. '
        'Veuillez réessayer.';
  }
}

class GoogleSignInResult {
  GoogleSignInResult({
    required this.googleUserId,
    this.idToken,
    this.accessToken,
    required this.email,
    required this.name,
    this.photoUrl,
  });

  /// ID Google unique et stable de l'utilisateur (le `sub`), disponible
  /// sur toutes les plateformes — c'est lui qui sert d'identifiant serveur.
  final String googleUserId;

  /// ID token Google (JWT). Non disponible sur le web avec le flux `signIn()`.
  final String? idToken;

  /// Access token OAuth2. Présent sur le web, absent sur mobile.
  final String? accessToken;

  final String email;
  final String name;
  final String? photoUrl;
}