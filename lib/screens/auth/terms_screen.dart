import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../theme/app_theme.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

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
                'Conditions Générales d\'Utilisation (CGU)',
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
                '''1. Présentation de l'Application
L'application Kivoo (ci-après « l'Application ») est une plateforme de petites annonces et de mise en relation permettant à des utilisateurs (ci-après « les Utilisateurs ») de publier, consulter et répondre à des annonces d'achat, de vente et de services.

2. Acceptation des CGU
L'accès et l'utilisation de l'Application sont soumis à l'acceptation inconditionnelle des présentes CGU. En créant un compte ou en utilisant Kivoo, l'Utilisateur reconnaît avoir lu, compris et accepté l'ensemble de ces termes.

3. Inscription et Sécurité du Compte
Pour accéder à l'ensemble des fonctionnalités (publication d'annonces, messagerie, etc.), l'Utilisateur doit créer un compte.
L'inscription peut s'effectuer par e-mail ou via des services d'authentification tiers (Google, Facebook).
L'Utilisateur est seul responsable de la confidentialité de ses identifiants et des activités effectuées depuis son compte.

4. Règles de Publication d'Annonces
L'Utilisateur s'engage à ne pas publier de contenus :
- Illicites, frauduleux, diffamatoires, violents ou haineux.
- Portant sur des produits ou services interdits par la loi en vigueur.
- Comportant des informations fausses ou trompeuses.
Kivoo se réserve le droit de supprimer sans préavis ni indemnité toute annonce ne respectant pas ces règles.

5. Responsabilité et Mise en Relation
Kivoo agit en qualité d'hébergeur et d'intermédiaire technique.
Kivoo ne garantit pas la qualité, la sécurité ou la conformité des biens et services vendus entre Utilisateurs.
Les transactions, paiements et remises en main propre s'effectuent sous la seule responsabilité des parties concernées.

6. Suspension et Résiliation
Kivoo se réserve le droit de suspendre ou de supprimer le compte de tout Utilisateur en cas de violation répétée ou grave des présentes CGU.''',
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