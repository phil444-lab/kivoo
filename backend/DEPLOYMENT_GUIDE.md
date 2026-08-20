# 🚀 Déploiement du Backend Kivoo sur Vercel

## 📋 Prérequis

- Compte [Vercel](https://vercel.com)
- Le projet poussé sur GitHub (déjà fait : `https://github.com/phil444-lab/kivoo.git`)
- Base MySQL sur Aiven (déjà configurée)
- Stockage Cloudinary (déjà configuré)
- Fichier Firebase service account JSON (déjà présent : `kivoo-d8521-firebase-adminsdk-fbsvc-dff099da48.json`)

## ⚠️ IMPORTANT - Limitations Vercel

Vercel est **serverless** (sans serveur persistant). Cela signifie :

1. **Socket.io ne fonctionnera PAS** - les conversations temps réel ne fonctionneront pas en production. Il faudra utiliser un service externe (Pusher, Ably, etc.) ou un polling.
2. **Les jobs de nettoyage (`setInterval`)** sont remplacés par **Vercel Cron Jobs** (configurés dans `vercel.json`, 1x/jour à minuit - limite du plan Hobby) ✅
3. **Le stockage local des fichiers** ne fonctionne pas - c'est déjà géré via Cloudinary ✅

## 🛠️ Fichiers déjà préparés

| Fichier | Rôle |
|---------|------|
| `backend/vercel.json` | Configuration Vercel (routes + Cron Jobs) |
| `backend/api/index.ts` | Point d'entrée serverless Vercel |
| `backend/api/cron/cleanup.ts` | Endpoint Cron pour le nettoyage (sessions, notifications, annonces expirées) |
| `backend/src/app.ts` | App Express séparée (réutilisable par Vercel et le serveur local) |
| `backend/package.json` | Script `vercel-build` = `prisma generate` |

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
| `DATABASE_URL` | Votre URL MySQL Aiven (voir votre dashboard Aiven) |
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
- Vérifier que l'IP d'Aiven autorise les connexions externes (Aiven → Service settings → Allow all IPs)

### Erreur "FIREBASE_SERVICE_ACCOUNT_JSON non défini"
- Vérifier que la variable est bien créée dans Vercel
- Le JSON doit être collé en entier, sans retour à la ligne

### CORS errors
- Vérifier que `FRONTEND_URL` correspond exactement à l'URL de votre app (sans `/` à la fin)

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