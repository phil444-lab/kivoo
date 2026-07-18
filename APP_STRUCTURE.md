Structure de l'application

Ce document décrit un modèle d'organisation de projet Flutter à suivre pour vos applications mobiles.

Racine
- `pubspec.yaml` — gestion des dépendances, assets et polices.
- `README.md`, `analysis_options.yaml` — documentation et règles d'analyse.

Plateformes
- `android/` — configuration Android (Gradle, manifest, ressources).
- `ios/` — configuration iOS (Xcode project, info.plist).

Lib
- `lib/main.dart` — point d'entrée de l'application.
- `lib/entry_point.dart` — initialisation (optional).
- `lib/constants.dart` — constantes globales.

Routes / Navigation
- `lib/route/router.dart` — centralise la navigation et la logique des routes.
- `lib/route/route_constants.dart` — identifiants de routes.

Écrans
- `lib/screens/` — dossiers par feature, exemple:
  - `home/` — `home_screen.dart`, `widgets/`
  - `product/` — `product_list.dart`, `product_detail.dart`
  - `auth/`, `profile/`, `checkout/`, etc.

Composants UI
- `lib/components/` — widgets réutilisables (boutons, cartes, headers, loaders).
  - organiser par type : `buttons/`, `cards/`, `nav/`.

Modèles
- `lib/models/` — classes de données sérialisables (ex. `product_model.dart`, `category_model.dart`).

Services et Répositories
- `lib/services/` — accès API, gestion de l'authentification (`api_service.dart`, `auth_service.dart`).
- `lib/repositories/` — logique métier / orchestration des données (`product_repository.dart`).

Theme & Styles
- `lib/theme/` — `app_theme.dart`, `colors.dart`, typographies et thèmes clairs/sombres.

Assets
- `assets/` — `images/`, `icons/`, `fonts/` (déclarer dans `pubspec.yaml`).

Tests
- `test/` — tests unitaires et widget (`widget_test.dart`).

Bonnes pratiques
- Séparer UI / logique / accès aux données (UI → Services → Repositories).
- Un écran = un dossier avec son fichier principal + widgets locaux pour faciliter la maintenance.
- Centraliser routes, thèmes et constantes pour réutilisabilité.
- Garder `models` simples et sérialisables (fromJson/toJson).
- Nommer les fichiers et dossiers de façon claire et cohérente.

Arborescence recommandée (résumé)

- lib/
  - main.dart
  - entry_point.dart
  - constants.dart
  - route/
    - router.dart
    - route_constants.dart
  - screens/
    - home/
      - home_screen.dart
      - widgets/
    - product/
      - product_list.dart
      - product_detail.dart
  - components/
    - buttons/
    - cards/
    - nav/
  - models/
    - product_model.dart
    - category_model.dart
  - services/
    - api_service.dart
    - auth_service.dart
  - repositories/
    - product_repository.dart
  - theme/
    - app_theme.dart
    - colors.dart
