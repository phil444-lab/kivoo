import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../theme/app_theme.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(
            FontAwesomeIcons.arrowLeft,
            color: isDark ? AppTheme.darkText : AppTheme.lightText,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Politique de Confidentialité',
                style: TextStyle(
                  color: isDark ? AppTheme.darkText : AppTheme.lightText,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Dernière mise à jour : 30 juillet 2026',
                style: TextStyle(
                  color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text(
                '''1. Données Personnelles Collectées
Dans le cadre de l'utilisation de Kivoo, nous sommes amenés à collecter les données suivantes :
- Informations de profil : Nom, prénom, adresse e-mail, photo de profil, numéro de téléphone.
- Données d'authentification tierce : Lorsque vous vous connectez via Google ou Facebook, nous collectons votre identifiant unique d'utilisateur ainsi que votre e-mail et nom associés à ce profil.
- Contenus publiés : Annonces, photos, descriptions, localisation approximative liée aux annonces.
- Données d'utilisation : Logs de connexion, type d'appareil, version de l'application.

2. Utilisation des Données
Vos données sont collectées pour :
- Permettre la création et la gestion de votre compte Utilisateur.
- Assurer le fonctionnement de la plateforme (affichage des annonces, messagerie instantanée).
- Sécuriser l'application et lutter contre le spam ou la fraude.
- Vous adresser des notifications liées à vos annonces ou messages.

3. Partage des Données
Vos données personnelles ne sont jamais vendues à des tiers. Elles peuvent être partagées uniquement dans les cas suivants :
- Autres utilisateurs : Les données publiques de votre profil (prénom, photo, annonces) sont visibles sur l'application.
- Prestataires de services : Nos hébergeurs web et services d'authentification (Google, Meta/Facebook, services de base de données).
- Obligations légales : Si la loi ou une autorité judiciaire l'exige.

4. Durée de Conservation
Vos données sont conservées tant que votre compte est actif. Vous pouvez demander la suppression complète de votre compte et de vos données personnelles à tout moment.

5. Vos Droits
Conformément à la réglementation sur la protection des données, vous disposez des droits suivants :
- Droit d'accès et de rectification de vos données.
- Droit à l'effacement (droit à l'oubli).
- Droit de retirer votre consentement pour la connexion via des services tiers (Google, Facebook).

6. Contact et Demande de Suppression
Pour toute question concernant cette politique ou pour exercer vos droits (suppression de compte / données), vous pouvez nous contacter à l'adresse e-mail suivante :
📧 support@kivoo.app''',
                style: TextStyle(
                  color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                  fontSize: 14,
                  height: 1.6,
                ),
                textAlign: TextAlign.justify,
              ),
            ],
          ),
        ),
      ),
    );
  }
}