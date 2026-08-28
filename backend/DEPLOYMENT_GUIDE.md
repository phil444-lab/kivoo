# 🚀 Déploiement du Backend Kivoo sur Vercel

## 📋 Prérequis

- Compte [Vercel](https://vercel.com)
- Le projet poussé sur GitHub (déjà fait : `https://github.com/phil444-lab/kivoo.git`)
- Base de données **TiDB Cloud** (compatible MySQL, ne s'endort jamais)
- Stockage Cloudinary (déjà configuré)
- Fichier Firebase service account JSON (déjà présent : `kivoo-d8521-firebase-adminsdk-fbsvc-dff099da48.json`)

## 🗄️ Migration Aiven → TiDB Cloud

### Pourquoi TiDB ?

- ✅ **Ne s'endort jamais** - contrairement à Aiven qui se met en veille après inactivité
- ✅ **Compatible MySQL** - Prisma fonctionne sans modification majeure du code
- ✅ **Gratuit pour démarrer** - TiDB Cloud offre un plan Serverless gratuit
- ✅ **Scalable automatiquement** - pas besoin de gérer la capacité
- ✅ **HTTPS/TLS inclus** - connexions sécurisées par défaut

### Étapes de migration

1. **Créer un compte TiDB Cloud** : https://tidbcloud.com
2. **Créer un cluster Serverless** (plan gratuit)
3. **Créer une base de données** nommée `kivoo`
4. **Récupérer la connection string** depuis le dashboard TiDB Cloud :
   ```
   mysql://<user>:<password>@<host>.tidbcloud.com:4000/kivoo
   ```
5. **Mettre à jour le fichier `.env`** (utiliser `sslaccept=strict` pour Prisma) :
   ```
   DATABASE_URL=mysql://<user>:<password>@<host>.tidbcloud.com:4000/kivoo?sslaccept=strict
   ```
6. **Régénérer le client Prisma** :
   ```bash
   cd backend
   npx prisma generate
   ```
7. **Pousser le schéma vers TiDB** :
   ```bash
   npx prisma db push
   ```
8. **Migrer les données existantes** (si nécessaire) :
   - Utiliser l'outil de migration de TiDB Cloud ou un outil comme `mysqldump` pour exporter depuis Aiven et importer vers TiDB
   - Ou simplement re-seeder : `npm run seed`

## ⚠️ IMPORTANT - Limitations Vercel

Vercel est **serverless** (sans serveur persistant). Cela signifie :

1. **Socket.io ne fonctionnera PAS** - les conversations temps réel ne fonctionneront pas en production. Il faudra utiliser un service externe (Pusher, Ably, etc.) ou un polling.
2. **Les jobs de nettoyage (`setInterval`)** sont remplacés par **Vercel Cron Jobs** (configurés dans `vercel.json`, 1x/jour à minuit - limite du plan Hobby) ✅
3. **Le stockage local des fichiers** ne fonctionne pas - c'est déjà géré via Cloudinary ✅
4. **La limite de 4,5 Mo sur le corps de requête** - les fichiers uploadés ne passent **PAS** par l'API Vercel. Ils sont uploadés **directement** vers Cloudinary depuis l'app Flutter via une signature signée. ✅

## 🛠️ Fichiers déjà préparés

| Fichier | Rôle |
|---------|------|
| `backend/vercel.json` | Configuration Vercel (routes + Cron Jobs) |
| `backend/api/index.ts` | Point d'entrée serverless Vercel |
| `backend/api/cron/cleanup.ts` | Endpoint Cron pour le nettoyage (sessions, notifications, annonces expirées) |
| `backend/src/app.ts` | App Express séparée (réutilisable par Vercel et le serveur local) |
| `backend/package.json` | Script `vercel-build` = `prisma generate` |
| `backend/src/routes/uploadRoutes.ts` | Endpoint `/api/uploads/signature` pour générer les signatures Cloudinary |
| `lib/services/cloudinary_service.dart` | Service Flutter pour l'upload direct vers Cloudinary |

## 📤 Upload direct Cloudinary (contourne la limite de 4,5 Mo)

### Comment ça fonctionne

1. **L'app Flutter** demande une signature signée au backend : `POST /api/uploads/signature` (avec le token JWT)
2. **Le backend** génère une signature Cloudinary signée (timestamp + signature HMAC) et la renvoie
3. **L'app Flutter** upload **directement** les images vers `https://api.cloudinary.com/v1_1/{cloud_name}/image/upload` avec la signature
4. **L'app Flutter** envoie ensuite les URLs Cloudinary au backend en JSON (payload minuscule, < 4,5 Mo)
5. **Le backend** stocke les URLs Cloudinary en base de données

### Avantages

- ✅ **Contourne totalement la limite de 4,5 Mo** de Vercel
- ✅ Les images haute qualité sont préservées
- ✅ Le backend ne traite plus les fichiers binaires (moins de charge CPU)
- ✅ Le payload JSON envoyé à Vercel reste minuscule

### Endpoints modifiés

| Endpoint | Avant | Après |
|----------|-------|-------|
| `POST /api/items` | multipart/form-data (fichiers) | JSON avec `images: [URLs Cloudinary]` |
| `PUT /api/items/:id` | multipart/form-data (fichiers) | JSON avec `images: [URLs Cloudinary]` |
| `POST /api/uploads/signature` | - | **Nouveau** : génère une signature Cloudinary |

## 📦 Étapes de déploiement

### 1. Pousser les modifications sur GitHub

```bash
git add .
git commit -m "feat: préparation déploiement Vercel"
git push origin main
```

### 2. Importer le projet sur Vercel

1. Aller sur [vercel.com/new](https://vercel.com/new)
2. Importer le repo GitHub `phil444-lab/kivoo`
3. **Root Directory** : sélectionner `backend`
4. Framework Preset : **Other**

### 3. Configurer les variables d'environnement

Dans Vercel → Settings → Environment Variables, ajouter :

| Variable | Valeur |
|----------|--------|
| `DATABASE_URL` | Votre URL TiDB Cloud (voir votre dashboard TiDB Cloud) |
| `JWT_SECRET` | Une clé secrète forte (ex: générée avec `openssl rand -base64 32`) |
| `JWT_EXPIRES_IN` | `7d` |
| `JWT_REFRESH_SECRET` | Une autre clé secrète forte |
| `JWT_REFRESH_EXPIRES_IN` | `30d` |
| `CLOUDINARY_CLOUD_NAME` | Votre Cloudinary cloud name (dashboard Cloudinary) |
| `CLOUDINARY_API_KEY` | Votre Cloudinary API key (dashboard Cloudinary) |
| `CLOUDINARY_API_SECRET` | Votre Cloudinary API secret (dashboard Cloudinary) |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | **Le contenu complet du fichier JSON** Firebase (voir étape 4) |
| `FRONTEND_URL` | L'URL de votre app Flutter web (ex: `https://kivoo.vercel.app`) |
| `NODE_ENV` | `production` |
| `CRON_SECRET` | Une clé secrète pour sécuriser l'endpoint cron (ex: `openssl rand -base64 32`) |

### 4. Configurer Firebase pour Vercel

Vercel ne peut pas lire de fichier local. Il faut passer le contenu du JSON en variable d'environnement :

1. Ouvrir le fichier `backend/kivoo-d8521-firebase-adminsdk-fbsvc-dff099da48.json`
2. Copier **tout le contenu** (c'est un objet JSON)
3. Dans Vercel, créer la variable `FIREBASE_SERVICE_ACCOUNT_JSON` avec ce contenu
4. ⚠️ Attention : le JSON contient des guillemets doubles. Vercel gère ça correctement si vous collez le contenu brut.

### 5. Déployer

1. Cliquer sur **Deploy**
2. Vercel va :
   - Installer les dépendances
   - Exécuter `prisma generate` (script `vercel-build`)
   - Compiler et déployer l'API

### 6. Vérifier le déploiement

Une fois déployé, tester :

```bash
# Health check
curl https://votre-backend.vercel.app/api/health
```

Réponse attendue :
```json
{
  "success": true,
  "message": "Kivoo API is running",
  "timestamp": "..."
}
```

## 🔄 Mise à jour du déploiement

À chaque push sur `main`, Vercel redéploie automatiquement.

## 🧪 Test en local (développement)

Le serveur local fonctionne toujours normalement :

```bash
cd backend
npm run dev
```

## 🚨 Dépannage

### Erreur Prisma "Can't reach database server"
- Vérifier que `DATABASE_URL` est correctement définie dans Vercel
- Vérifier que l'URL TiDB est correcte (format : `mysql://<user>:<password>@<host>.tidbcloud.com:4000/kivoo?sslaccept=strict`)
- TiDB Cloud Serverless accepte les connexions de n'importe où (pas de restriction IP par défaut)

### Erreur "FIREBASE_SERVICE_ACCOUNT_JSON non défini"
- Vérifier que la variable est bien créée dans Vercel
- Le JSON doit être collé en entier, sans retour à la ligne

### CORS errors
- Vérifier que `FRONTEND_URL` correspond exactement à l'URL de votre app (sans `/` à la fin)
- Pour autoriser plusieurs origines (app Flutter + dashboard admin local), servez-vous de la variable **`FRONTEND_URLS`** (liste d'origines séparées par des virgules). Le backend accepte par défaut `http://localhost:5174` (dashboard admin en dev) et `http://localhost:5173`, en plus de `FRONTEND_URL` :
  ```
  FRONTEND_URLS=http://localhost:5173,http://localhost:5174,https://mon-admin.vercel.app
  ```
  > En mode dev, le dashboard admin utilise le proxy Vite vers Vercel : les requêtes
  > sont vues comme provenant de `localhost:5174` (même origine côté navigateur), donc
  > le CORS n'est nécessaire que si vous accédez à l'API directement (`VITE_API_URL`).

### Socket.io ne fonctionne pas
- C'est normal sur Vercel (serverless). Les messages seront quand même sauvegardés en base, mais sans temps réel.
- Solution future : utiliser Pusher/Ably ou un serveur dédié (Railway, Render, Fly.io)

### Cron Jobs
- Les jobs de nettoyage sont configurés via `vercel.json` (1x/jour à minuit UTC)
- ⚠️ Le plan **Hobby** (gratuit) limite les cron jobs à **1 exécution par jour**
- L'endpoint `/api/cron/cleanup` est sécurisé par le header `Authorization: Bearer <CRON_SECRET>`
- Pour tester manuellement : `curl -H "Authorization: Bearer <CRON_SECRET>" https://votre-backend.vercel.app/api/cron/cleanup`
- Pour exécuter plus souvent (toutes les heures), il faut passer au plan **Pro** ($20/mois)

## 📝 Notes importantes

- **Le fichier `.env` local** ne doit **jamais** être poussé sur GitHub (il est déjà dans `.gitignore`)
- **Le fichier Firebase JSON** ne doit **jamais** être poussé sur GitHub (il est déjà dans `.gitignore`)
- Les secrets sont gérés par Vercel, pas par le code