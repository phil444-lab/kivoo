import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: '329144921089-3lkhb9dv7umhbtnolfjitd1fvaar0q1t.apps.googleusercontent.com',
  );

  /// Déclenche la connexion Google et retourne l'idToken et les infos utilisateur
  Future<GoogleSignInResult?> signIn() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();

      if (account == null) {
        // L'utilisateur a annulé la connexion
        return null;
      }

      final GoogleSignInAuthentication auth =
          await account.authentication;

      final String? idToken = auth.idToken;

      if (idToken == null) {
        throw Exception('Impossible d\'obtenir le token Google');
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
  final String idToken;
  final String email;
  final String name;
  final String? photoUrl;

  GoogleSignInResult({
    required this.idToken,
    required this.email,
    required this.name,
    this.photoUrl,
  });
}