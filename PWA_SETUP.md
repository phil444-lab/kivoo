# Kivoo PWA — App web mobile (Flutter Web)

Ce projet est maintenant compilable pour le **web** afin de fournir une **PWA mobile "copie conforme"** de l'application Flutter (utile en premier lieu pour les utilisateurs **iPhone**, tant que l'app n'est pas sur l'App Store).

## 🚀 Démarrer en local (web)

```bash
flutter run -d chrome
# ou sur un port fixe (recommandé pour le CORS) :
flutter run -d web-server --web-port 8765 --release
```

## 📦 Build de production

```bash
flutter build web --release
Copy-Item web\sw.js build\web\flutter_service_worker.js -Force
# Le bundle est généré dans build/web (index.html, manifest.json,
# flutter_service_worker.js, main.dart.js, icons/, splash/, canvaskit/)
# NB : web/vercel.json et web/sw.js sont automatiquement copiés dans build/web.
```

> ⚠️ **Service worker** : Flutter 3.44 génère un `flutter_service_worker.js` **vide** (SW Flutter déprécié). Le fichier `web/sw.js` (SW PWA minimal : shell offline + cache assets) est copié automatiquement dans `build/web/sw.js` par le build — il ne reste qu'à le recopier sur `flutter_service_worker.js` (commande `Copy-Item` ci-dessus) pour que le loader Flutter l'enregistre sans warning. À refaire après chaque build.

## 🚀 Déploiement manuel sur Vercel (sans CLI, sans Git)

Le fichier `web/vercel.json` (rewrites + headers de cache) est embarqué dans le build, donc `build/web` est **prêt à déployer tel quel**.

1. `flutter build web --release`
2. Aller sur **https://vercel.com/new** (connecté à votre compte)
3. Section **« Deploy without Git »** → glisser-déposer le dossier `build/web`
4. Nommer le projet (ex. `kivoo-web`) → **Deploy**
5. Récupérer l'URL : `https://kivoo-web.vercel.app`

### ⚠️ Étape obligatoire après le premier déploiement : CORS backend

Le backend tourne en `NODE_ENV=production` sur Vercel : seules les origines listées dans `FRONTEND_URLS` sont acceptées.

1. Dashboard Vercel → projet **backend** (kivoo-api) → **Settings → Environment Variables**
2. Variable `FRONTEND_URLS` : **ajouter** l'URL de la PWA (en conservant les valeurs existantes), ex. :
   ```
   FRONTEND_URLS=http://localhost:5173,http://localhost:5174,https://kivoo-web.vercel.app
   ```
   (origines sans `/` final ni chemin)
3. **Redéployer le backend** (Deployments → dernier déploiement → Redeploy) pour que la variable prenne effet.
4. Tester : ouvrir la PWA → connexion/inscription. Si erreur CORS dans la console → variable non appliquée / backend pas redéployé.

### 🔁 Redéployer sans recréer le projet (CLI Vercel)

Le projet créé par drag & drop peut être **lié au CLI une seule fois** — ensuite chaque déploiement part sur le même projet (même URL, CORS intact).

Configuration initiale :

```powershell
npm install -g vercel      # si pas déjà fait
vercel login               # authentification navigateur (une fois)
cd deploy\kivoo-web
vercel link --yes --project kivoo-web   # le nom du projet créé via drag & drop
```
*(Si vous avez plusieurs équipes Vercel, ajoutez `--scope nom-de-l-equipe`.)*

Puis, chaque mise à jour = **une commande** à la racine du repo :

```powershell
.\deploy-web.ps1              # build + patch service worker + déploiement production
.\deploy-web.ps1 -SkipBuild   # redéploie le build existant tel quel
```

Le script (`deploy-web.ps1`) synchronise `build\web` vers `deploy\kivoo-web` (en préservant le lien `.vercel\`), puis déploie avec `vercel deploy --prod`. Le dossier `deploy/` et `.vercel/` sont ignorés par git.

### 🚀 Déploiement via GitHub → Vercel (recommandé à terme)

> ⚠️ Les builders Vercel n'ont **pas le SDK Flutter** : impossible de simplement « connecter le repo » et laisser Vercel builder. Deux approches possibles :

#### Option B — GitHub Actions (recommandée, CI/CD complet)

Le workflow **`.github/workflows/deploy-web.yml`** est déjà prêt : il installe Flutter, build la PWA et déploie vers Vercel à chaque push sur `master` (ou manuellement via *Run workflow*).

Configuration initiale (une seule fois) :

1. **Créer le projet Vercel une première fois** : glisser-déposer `build/web` sur https://vercel.com/new (cf. section précédente) → projet `kivoo-web` créé avec son URL définitive.
2. **Récupérer les identifiants** (page du projet Vercel → **Settings → General**) :
   - `Vercel Organization ID`
   - `Vercel Project ID`
3. **Créer un token** : https://vercel.com/account/tokens → *Create Token* (scope : votre compte)
4. **Ajouter 3 secrets** : repo GitHub → **Settings → Secrets and variables → Actions → New repository secret** :
   - `VERCEL_TOKEN` = le token
   - `VERCEL_ORG_ID` = l'Organization ID
   - `VERCEL_PROJECT_ID` = le Project ID
5. Committer et pousser le workflow :
   ```bash
   git add .github/workflows/deploy-web.yml
   git commit -m "ci: déploiement PWA web vers Vercel via GitHub Actions"
   git push
   ```
   (le workflow se déclenche aussi manuellement : onglet **Actions** → *Deploy Web PWA (Vercel)* → **Run workflow**)

Chaque push modifiant `lib/`, `web/` ou `pubspec.yaml` redéploiera automatiquement la PWA sur la **même URL**.

#### Option A — Committer le build (plus simple, sans secrets)

1. Autoriser `build/web` dans git (ajouter au `.gitignore`) :
   ```gitignore
   /build/*
   !/build/web
   build/web/main.dart.js.map
   ```
2. Vercel → **Add New Project** → importer `phil444-lab/kivoo` → Framework Preset : **Other**, Build Command : *(vide)*, Output Directory : `build/web`
3. Chaque mise à jour : `flutter build web --release` + `Copy-Item web\sw.js build\web\flutter_service_worker.js` → commit → push → Vercel redéploie automatiquement.

## ✅ Ce qui a été adapté pour le web

| Élément | Adaptation |
|---|---|
| `lib/utils/picked_image.dart` | **Nouveau** — wrapper cross-platform (XFile + bytes) pour la sélection d'images |
| `lib/services/image_compression_service.dart` | Compression basée sur `compressWithList` (mobile **et** web), plus de `dart:io`/`path_provider` |
| `lib/services/cloudinary_service.dart` | Upload via `MultipartFile.fromBytes`, plus de `File`/`SocketException` |
| `lib/services/conversation_service.dart` | Envoi d'image via `fromBytes` |
| `lib/services/auth_service.dart` | Upload photo de profil via `fromBytes` |
| `lib/providers/auth_provider.dart` | `uploadPhoto(PickedImage)` |
| `lib/screens/auth/edit_profile_screen.dart` | `PickedImage` + `Image(image: …)` cross-platform |
| `lib/screens/sell/sell_screen.dart` | idem (galerie d'annonces) |
| `lib/screens/home/conversation_detail_screen.dart` | idem (envoi d'image dans le chat) |
| `lib/services/notification_service.dart` | Guard `kIsWeb` : sur web, pas de notifications locales Flutter ; permission + token FCM si VAPID configurée |
| `lib/main.dart` | Init Firebase web conditionnelle + **coquille mobile** (`MobileAppShell`) qui contraint l'app à 480 px centrés sur grand écran |
| `web/index.html` | Meta PWA iOS (`apple-mobile-web-app-capable`, `black-translucent`), `theme-color` #2563EB |
| `web/manifest.json` | Branding Kivoo (nom, couleurs #2563EB, `start_url` `/`) |
| `backend/src/app.ts` | CORS : autorise `localhost:*` en développement (Flutter web dev) |

## 🔔 Notifications push web (optionnel, à compléter)

1. **Firebase Console** → Paramètres du projet → **Vos applications** → ajoutez une app **Web**, copiez la config.
2. Renseignez la config dans `lib/main.dart` (`_kFirebaseWebOptions`) et passez `_kFirebaseWebConfigured` à `true`.
3. Firebase Console → **Cloud Messaging** → **Certificats push Web** → générez une paire de clés et copiez la **clé VAPID** dans `lib/constants.dart` → `AppConstants.fcmVapidKey`.
4. Le service worker FCM : ajoutez un fichier `web/firebase-messaging-sw.js` (fourni par la doc Firebase) pour le background push.

> Sans cette config, l'application web fonctionne normalement — seules les notifications push web sont désactivées. Les notifications in-app (via l'API backend) restent fonctionnelles.

## 🌐 CORS backend (production)

Dans les variables d'environnement du backend (local `.env` **et** Vercel), ajoutez l'URL de la PWA déployée :

```
FRONTEND_URLS=https://kivoo-api.vercel.app/api,https://VOTRE-URL-PWA.example
```

⚠️ En production (`NODE_ENV=production`), seules les origines listées dans `FRONTEND_URLS` sont acceptées. En développement, tous les ports `localhost` / `127.0.0.1` sont autorisés.

## 📱 Installation sur iPhone (Safari)

1. Ouvrir l'URL de la PWA dans **Safari**.
2. Bouton **Partager** → **Sur l'écran d'accueil**.
3. L'app s'installe en plein écran (`display: standalone`), avec son icône et sa splash screen — comme une app native.

## ⚠️ Limitations connues (web)

- **Google Sign-In** : nécessite que l'origine (URL de la PWA) soit ajoutée comme domaine autorisé dans la console Google Cloud (OAuth client « Web » — le `serverClientId` déjà configuré est utilisé).
- **Notifications locales** (Android/iOS natives) : non disponibles sur web, remplacées par les notifications du navigateur si Firebase web est configuré.
- Le build généré est également **compatible WebAssembly** (`--wasm` optionnel pour de meilleures performances).
