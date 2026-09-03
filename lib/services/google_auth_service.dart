import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/services.dart' show PlatformException;
import 'package:google_sign_in/google_sign_in.dart';

/// Exception signalant que l'utilisateur a annulé la connexion Google
/// (popup fermée, retour arrière, autorisations refusées...).
///
/// Ce n'est **pas une erreur** à afficher : [AuthProvider.loginWithGoogle]
/// l'intercepte et retourne simplement `false` (écran inchangé).
class GoogleSignInCanceledException implements Exception {}

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

  /// Déclenche la connexion Google et retourne l'idToken et les infos utilisateur.
  ///
  /// - Succès → [GoogleSignInResult]
  /// - Annulation utilisateur → [GoogleSignInCanceledException]
  /// - Erreur → [Exception] avec un message **utilisateur** en français
  ///   (le détail technique complet est journalisé en console via debugPrint).
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
        // Annulation via l'API (retour null, surtout sur mobile)
        throw GoogleSignInCanceledException();
      }

      final auth = await account.authentication;

      final idToken = auth.idToken;

      if (idToken == null) {
        throw Exception(
          kIsWeb
              ? "Le panneau de connexion Google n'a pas fourni de jeton "
                  "d'identification. Veuillez réessayer."
              : "Impossible d'obtenir le jeton Google. Veuillez réessayer.",
        );
      }

      return GoogleSignInResult(
        idToken: idToken,
        email: account.email,
        name: account.displayName ?? account.email.split('@').first,
        photoUrl: account.photoUrl,
      );
    } on GoogleSignInCanceledException {
      rethrow;
    } catch (e) {
      if (_isUserCancellation(e)) {
        // Fermeture de la popup / annulation volontaire : ce n'est pas un
        // échec, on remonte « en silence » pour ne rien afficher à l'écran.
        throw GoogleSignInCanceledException();
      }
      // Erreur réelle : détail technique en console, message lisible en UI.
      debugPrint('GoogleSignIn — erreur technique : $e');
      throw Exception(_userMessage(e));
    }
  }

  /// Déconnexion Google
  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  /// Détecte les annulations utilisateur d'après les codes/messages renvoyés
  /// par le plugin selon la plateforme (iOS / Android / Web).
  static bool _isUserCancellation(Object e) {
    final code = e is PlatformException ? e.code : '';
    final message = e is PlatformException
        ? (e.message ?? e.details?.toString() ?? '')
        : e.toString();
    // Les erreurs GIS arrivent parfois avec des espaces (« Popup closed »)
    // et parfois avec des underscores (« popup_closed_by_user »).
    final m = '$code $message'.toLowerCase();
    final n = m.replaceAll(' ', '_');
    return m.contains('canceled') ||
        m.contains('cancelled') ||
        n.contains('popup_closed') ||
        n.contains('popup_failed_to_open') ||
        n.contains('access_denied') ||
        m.contains('12501'); // Android : code interne USER_CANCELED
  }

  /// Traduit une erreur technique en message compréhensible pour l'utilisateur.
  static String _userMessage(Object e) {
    final code = e is PlatformException ? e.code : '';
    final message = e is PlatformException
        ? (e.message ?? e.details?.toString() ?? '')
        : e.toString();
    final m = '$code $message'.toLowerCase();
    final n = m.replaceAll(' ', '_');

    if (n.contains('popup_failed_to_open') ||
        n.contains('popup_closed') ||
        m.contains('popup blocked')) {
      return 'La fenêtre de connexion Google a été fermée ou bloquée. '
          'Autorisez les fenêtres contextuelles pour ce site et réessayez.';
    }
    if (m.contains('network') ||
        m.contains('socketexception') ||
        m.contains('failed host lookup') ||
        m.contains('clientconnector') ||
        m.contains('xmlhttprequest error')) {
      return 'Connexion à Google impossible. '
          'Vérifiez votre accès à Internet puis réessayez.';
    }
    if (m.contains('timeout') || m.contains('timed out')) {
      return 'La connexion Google a mis trop de temps à répondre. '
          'Veuillez réessayer.';
    }
    if (m.contains('12500') || m.contains('apiexception')) {
      // Erreur de configuration côté app (developer_error)
      return 'Connexion Google momentanément indisponible. '
          'Réessayez plus tard.';
    }
    return "Impossible de se connecter avec Google pour le moment. "
        "Veuillez réessayer.";
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