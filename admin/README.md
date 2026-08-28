# Kivoo Admin Dashboard

Application **React + TypeScript + Vite** de gestion administrative du marketplace Kivoo.
Elle couvre la modération, la gestion des utilisateurs, des annonces, du référentiel
et les communications système.

## Prérequis

Deux modes sont possibles :

### Mode A — Backend local (développement)
- Backend démarré sur `http://localhost:5000` (voir `backend/`)
- Base de données initialisée et **seed exécuté** pour créer le compte admin :
  ```bash
  cd backend
  npm run db:generate
  npm run seed
  ```
  Le seed crée un compte avec le rôle `admin` :
  - Email : `ADMIN_EMAIL` (défaut `admin@kivoo.com`)
  - Mot de passe : `ADMIN_PASSWORD` (défaut `Admin1234!`)

### Mode B — Backend en ligne (recommandé pour les tests)
Le frontend admin reste en local, il pointe vers le backend déjà déployé sur **Vercel**
(avec la base sur **TiDB**). Dans `admin/.env` :

```env
# URL du backend Vercel (sans /api, sans / final)
VITE_API_PROXY_TARGET=https://votre-backend.vercel.app
```

> Renseignez aussi `VITE_API_URL=https://votre-backend.vercel.app/api` pour un accès
> direct (sans proxy) lors d'un build/preview.

## Installation et lancement

```bash
cd admin
cp .env.example .env   # puis éditez d'après votre cas (Mode A ou B)
npm install
npm run dev
```

L'application tourne sur **http://localhost:5174**. Les requêtes `/api` sont proxifiées
par Vite (`vite.config.ts`) vers la cible configurée :
- Mode A → `http://localhost:5000`
- Mode B → l'URL réelle du backend Vercel (via `VITE_API_PROXY_TARGET`)

### Build de production

```bash
npm run build
npm run preview
```

> Lorsque `VITE_API_URL` est renseignée au build, le client cible directement l'API
> distante sans passer par le proxy relatif `/api`.

## Déploiement sur Vercel

Le dashboard admin est déployé comme site **statique** (build Vite) avec le routing
géré par React Router — `admin/vercel.json` contient la règle de *rewrite* SPA
(tous les chemins servent `index.html`) pour éviter les 404 au rafraîchissement
de `/categories`, `/users`, etc.

### 1. Variable d'environnement (obligatoire avant le premier déploiement)

En production il n'y a **pas de proxy Vite** : le client doit cibler l'API
directement via `VITE_API_URL` (lue au **build** — la modifier implique un
redéploiement) :

| Variable | Valeur | Environnements |
|----------|--------|----------------|
| `VITE_API_URL` | `https://kivoo-api.vercel.app/api` | Production + Preview |

### 2. Création du projet (dashboard)

1. **Add New… → Project** → importer le repo GitHub `kivoo`
2. **Root Directory** : `admin` (le framework **Vite** est détecté automatiquement,
   build `npm run build`, sortie `dist`)
3. Renseigner `VITE_API_URL` (voir ci-dessus) puis **Deploy**
4. Noter le domaine attribué (ex. `https://kivoo-admin.vercel.app`)

### 3. Autoriser le domaine côté backend (CORS)

Dans le projet **backend** sur Vercel : *Settings → Environment Variables* →
ajouter le domaine de l'admin à `FRONTEND_URLS` (origines séparées par des
virgules), puis **Redeploy** le backend :

```
FRONTEND_URLS=...,https://kivoo-admin.vercel.app
```

### 4. Alternative — Vercel CLI

```bash
npx vercel --cwd admin          # premier déploiement (liera le projet)
npx vercel env add VITE_API_URL production
npx vercel --prod --cwd admin   # déploiements suivants
```

### 5. Vérification

```bash
curl https://kivoo-api.vercel.app/api/health
```
Puis ouvrir l'URL de l'admin, se connecter avec le compte admin et vérifier que
les modules (statistiques, catégories, annonces…) chargent bien les données.

### Authentification

- Route utilisée : `POST /api/auth/login` (identifier + password)
- Le dashboard refuse toute connexion si `user.role !== 'admin'`
- Gestion automatique du `refresh-token` côté client (rejeu après 401)
- Déconnexion : `POST /api/auth/logout` (invalide la session)

## Modules disponibles

| Route | Description |
|-------|-------------|
| `/` | Tableau de bord — KPIs + graphiques (inscriptions/annonces, répartition par ville) |
| `/reports` | Modération des signalements (pending/reviewed/resolved/dismissed) + actions (supprimer l'annonce, avertir, bannir, classer) |
| `/validation` | File de validation des annonces en attente (approuver/rejeter) |
| `/items` | Annonces — recherche/filtres, détail (photos Cloudinary, vues, favoris), statut, mise en avant, suppression |
| `/users` | Utilisateurs — recherche, profil (annonces/avis/sessions), bannir/activer, badge vérifié, invalider les sessions, avertir |
| `/categories` | CRUD Catégories & Sous-catégories (2 niveaux) |
| `/locations` | CRUD Départements / Villes / Quartiers du Bénin |
| `/featured-options` | Configuration des offres sponsorisées |
| `/notifications` | Envoi de notifications in-app/push ciblées + historique |

## Thème

Les couleurs reprennent **exactement** les tokens de `lib/theme/app_theme.dart`
(`#2563EB` / `#1D4ED8`, fond sombre `#12161a`/`#1d232a`, clair `#f0f2f5`/`#ffffff`,
police Inter, rayons 16/12 px) via des variables CSS et un toggle clair/sombre
(`data-theme`).

## API backend d'exposition (`/api/admin`)

Toutes les routes sont protégées par `protect` + `isAdmin` (vérifie `role === 'admin'`).

- `GET  /stats`, `GET  /analytics?days=`
- `GET /reports`, `PATCH /reports/:id/status`, `POST /reports/:id/moderate`
- `GET /moderation/items/pending`, `PATCH /moderation/items/:id/review`
- `GET /items`, `GET /items/:id`, `PATCH /items/:id`, `DELETE /items/:id`
- `GET /users`, `GET /users/:id`, `PATCH /users/:id`, `POST /users/:id/invalidate-sessions`, `POST /users/:id/warn`
- `GET|POST /categories`, `PATCH|DELETE /categories/:id`
- `GET /locations/tree`, CRUD `/departments`, `/cities`, `/districts`
- `GET|POST /featured-options`, `PATCH|DELETE /featured-options/:id`
- `POST /notifications/broadcast`, `GET /notifications/history`