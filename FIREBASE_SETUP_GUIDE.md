# 🔥 Configuration Firebase Cloud Messaging (FCM) — Guide étape par étape

Ce guide vous explique comment configurer Firebase pour que les notifications push fonctionnent avec l'application Kivoo.

---

## Étape 1 : Créer un projet Firebase

1. Allez sur [https://console.firebase.google.com](https://console.firebase.google.com)
2. Cliquez sur **"Créer un projet"**
3. Nommez le projet (ex: `kivoo`)
4. Suivez les étapes (Google Analytics est optionnel)

---

## Étape 2 : Ajouter l'application Android

1. Dans la console Firebase, cliquez sur **l'icône Android** (🤖)
2. **Package name** : `com.example.kivoo` (celui de votre `android/app/build.gradle.kts`)
3. **Nom de l'application** : `KIVOO`
4. Cliquez sur **"Enregistrer l'application"**
5. **Téléchargez le fichier `google-services.json`** et placez-le dans :
   ```
   android/app/google-services.json
   ```

---

## Étape 3 : Ajouter l'application iOS (optionnel)

Si vous voulez le support iOS :

1. Cliquez sur **l'icône iOS** (🍎)
2. **Bundle ID** : `com.example.kivoo` (celui de votre projet Xcode)
3. Téléchargez le fichier `GoogleService-Info.plist` et placez-le dans :
   ```
   ios/Runner/GoogleService-Info.plist
   ```

---

## Étape 4 : Générer la clé privée du service (backend)

1. Dans la console Firebase, allez dans **Paramètres du projet** (⚙️) → **Comptes de service**
2. Cliquez sur **"Générer une nouvelle clé privée"**
3. Un fichier JSON sera téléchargé (ex: `kivoo-firebase-adminsdk-xxxxx.json`)
4. Placez ce fichier dans le dossier `backend/` avec le nom :
   ```
   backend/firebase-service-account.json
   ```

---

## Étape 5 : Configurer le backend

Le fichier `.env` du backend contient déjà la ligne :
```
FIREBASE_SERVICE_ACCOUNT_PATH=./firebase-service-account.json
```

**Vérifiez** que le chemin pointe bien vers le fichier JSON téléchargé.

---

## Étape 6 : Mettre à jour la base de données

Le nouveau modèle `PushToken` nécessite une mise à jour de la base de données :

```bash
cd backend
npx prisma db push
```

Cette commande crée la table `push_tokens`.

---

## Étape 7 : Redémarrer le backend

```bash
cd backend
npm run dev
```

Vous devriez voir dans les logs :
```
🔥 Firebase Admin SDK initialisé
```

Si ce message n'apparaît pas, vérifiez que :
- Le fichier `firebase-service-account.json` existe dans `backend/`
- Le chemin dans `.env` est correct

---

## Ce qui est déjà implémenté ✅

### Backend
- **Modèle `PushToken`** : stocke les tokens FCM des utilisateurs (table `push_tokens`)
- **Service `fcmService.ts`** :
  - `registerPushToken()` : enregistre/met à jour un token
  - `unregisterPushToken()` : supprime un token (déconnexion)
  - `sendPushNotification()` : envoie les notifications à tous les appareils de l'utilisateur
  - `createAndSendNotification()` : sauvegarde dans la BD **et** envoie le push
- **Contrôleur `notificationController.ts`** :
  - `GET /api/notifications` : liste les notifications de l'utilisateur (avec pagination + compteur non-lus)
  - `PUT /api/notifications/:id/read` : marque une notification comme lue
  - `PUT /api/notifications/read-all` : marque toutes les notifications comme lues
  - `POST /api/notifications/push-token` : enregistre le token FCM
  - `DELETE /api/notifications/push-token` : supprime le token FCM
- **Intégration conversations** : quand un message est envoyé, le backend crée une notification et envoie un push au destinataire

### Frontend
- **`NotificationService`** : gère FCM côté client
  - Demande la permission
  - Récupère le token FCM et l'enregistre sur le backend
  - Gère les notifications au premier plan, en arrière-plan, et au clic
- **`NotificationProvider`** : stocke les notifications, le compteur non-lu, et le token
- **`NotificationsScreen`** : écran de liste des notifications avec :
  - Icônes par type (message ✉️, favori ❤️, etc.)
  - Badge bleu pour les notifications non-lues
  - Bouton "tout marquer comme lu"
  - Pull-to-refresh
- **`main.dart`** : initialise Firebase au démarrage
- **Android** : permissions, plugin Google Services, FirebaseMessagingService

---

## Note importante

Pour que le build Android fonctionne, le fichier `android/app/google-services.json` doit exister. **Sans ce fichier, le build échouera** avec une erreur comme :

```
File google-services.json is missing.
```

Si vous voulez tester sans Firebase pour l'instant, commentez le plugin dans `android/app/build.gradle.kts` :

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    // id("com.google.gms.google-services")  // ← commentez cette ligne
    id("dev.flutter.flutter-gradle-plugin")
}