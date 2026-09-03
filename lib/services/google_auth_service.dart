import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // Web : le plugin google_sign_in_web ne supporte pas serverClientId
    // (assert explicite) et lit le client ID web depuis le meta tag
    // <meta name="google-signin-client_id"> de web/index.html.
    // Mobile : serverClientId (client « Application Web ») est requis pour
    // obtenir un idToken accepté par le backend.
    serverClientId: kIsWeb
        ? null
        : '329144921089-3lkhb9dv7umhbtnolfjitd1fvaar0q1t.apps.googleusercontent.com',
  );

  /// Déclenche la connexion Google et retourne l'idToken et les infos utilisateur
  Future<GoogleSignInResult?> signIn() async {
    try {
      GoogleSignInAccount? account;

      // Sur web : tenter d'abord le flux « One Tap » (signInSilently), seul
      // flux qui renvoie un idToken. Le popup classique (signIn) renvoie un
      // profil synthétisé via People API SANS idToken.
      if (kIsWeb) {
        account = await _googleSignIn.signInSilently();
      }
      account ??= await _googleSignIn.signIn();

      if (account == null) {
        // L'utilisateur a annulé la connexion
        return null;
      }

      final auth =
          await account.authentication;

      final idToken = auth.idToken;

      if (idToken == null) {
        throw Exception(
          kIsWeb
              ? "Le panneau de connexion Google n'a pas fourni de jeton "
                  "d'identification. Veuillez réessayer."
              : 'Impossible d\'obtenir le token Google',
        );
      }

      return GoogleSignInResult(
        idToken: idToken,
        email: account.email,
        name: account.displayName ?? account.email.split('@').first,
        photoUrl: account.photoUrl,
      );
    } catch (e) {
      throw Exception('Erreur lors de la connexion Google: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  /// Déconnexion Google
  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}

class GoogleSignInResult {

  GoogleSignInResult({
    required this.idToken,
    required this.email,
    required this.name,
    this.photoUrl,
  });
  final String idToken;
  final String email;
  final String name;
  final String? photoUrl;
}