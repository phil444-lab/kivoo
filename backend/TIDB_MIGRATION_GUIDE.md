# 🗄️ Guide de Migration Aiven → TiDB Cloud

## 📌 Pourquoi migrer vers TiDB ?

Le problème principal avec **Aiven MySQL** est que le service **s'endort** après une période d'inactivité, ce qui cause des délais de réponse importants au premier appel après une pause.

**TiDB Cloud** résout ce problème car :
- ✅ **Ne s'endort jamais** - toujours disponible
- ✅ **Compatible MySQL** - votre code Prisma fonctionne sans modification majeure
- ✅ **Plan Serverless gratuit** - idéal pour démarrer
- ✅ **Scalable automatiquement** - pas de gestion de capacité
- ✅ **TLS/SSL inclus** - connexions sécurisées par défaut

## 🚀 Étapes de migration

### Étape 1 : Créer un compte TiDB Cloud

1. Aller sur [https://tidbcloud.com](https://tidbcloud.com)
2. Créer un compte (gratuit)
3. Se connecter au dashboard

### Étape 2 : Créer un cluster Serverless

1. Cliquer sur **"Create Cluster"**
2. Choisir **"Serverless"** (plan gratuit)
3. Choisir une région proche de vos utilisateurs (ex: `eu-central-1` pour l'Europe)
4. Cliquer sur **"Create"**

### Étape 3 : Créer la base de données

1. Dans le dashboard du cluster, cliquer sur **"Connect"**
2. Copier la connection string fournie (format MySQL)
3. Créer une base de données nommée `kivoo` :
   ```sql
   CREATE DATABASE kivoo;
   ```

### Étape 4 : Récupérer la connection string

La connection string TiDB Cloud a ce format :
```
mysql://<user>:<password>@<host>.tidbcloud.com:4000/kivoo
```

⚠️ **Important pour Prisma** : Utiliser `sslaccept=strict` (pas `ssl-mode=REQUIRED`) car TiDB Serverless exige une connexion TLS sécurisée.
```
mysql://<user>:<password>@<host>.tidbcloud.com:4000/kivoo?sslaccept=strict
```

### Étape 5 : Mettre à jour le fichier `.env`

```env

# Nouvelle URL TiDB (remplacez <PASSWORD> par votre vrai mot de passe)
# sslaccept=strict est OBLIGATOIRE pour TiDB Serverless (connexion TLS)
DATABASE_URL=mysql://<user>:<password>@<host>.tidbcloud.com:4000/kivoo?sslaccept=strict
```

### Étape 6 : Régénérer le client Prisma

```bash
cd backend
npx prisma generate
```

### Étape 7 : Pousser le schéma vers TiDB

```bash
npx prisma db push
```

### Étape 8 : Migrer les données (optionnel)

Si vous avez des données existantes dans Aiven, vous pouvez :

#### Option A : Re-seeder (recommandé pour les données de référence)
```bash
npm run seed
```

#### Option B : Migration complète avec mysqldump

1. **Exporter depuis Aiven** :
   ```bash
   mysqldump -h mysql-13b36903-kivoo-ce99.c.aivencloud.com -P 28409 -u avnadmin -p defaultdb > kivoo_backup.sql
   ```

2. **Importer vers TiDB** :
   ```bash
   mysql -h <host>.tidbcloud.com -P 4000 -u <user> -p kivoo < kivoo_backup.sql
   ```

#### Option C : Utiliser l'outil de migration TiDB Cloud
- TiDB Cloud propose un outil de migration intégré dans le dashboard
- Suivre les instructions dans : **Dashboard → Cluster → Import**

### Étape 9 : Mettre à jour Vercel

1. Aller sur **Vercel → Votre projet → Settings → Environment Variables**
2. Mettre à jour `DATABASE_URL` avec la nouvelle URL TiDB
3. Redéployer

### Étape 10 : Vérifier

```bash
# Test local
cd backend
npm run dev

# Test de connexion
curl http://localhost:5000/api/health
```

## 🔧 Dépannage

### Erreur "Can't reach database server"
- Vérifier que l'URL TiDB est correcte
- Vérifier que le mot de passe ne contient pas de caractères spéciaux non encodés (utiliser `%40` pour `@`, etc.)
- TiDB Serverless accepte les connexions de n'importe où (pas de whitelist IP)

### Erreur "Connections using insecure transport are prohibited"
- S'assurer que `?sslaccept=strict` est bien dans l'URL (utiliser `sslaccept=strict`, PAS `ssl-mode=REQUIRED`)
- TiDB Cloud Serverless exige TLS et bloque les connexions non sécurisées

### Erreur "Access denied"
- Vérifier le nom d'utilisateur et le mot de passe
- S'assurer que la base `kivoo` existe

## 📊 Comparaison Aiven vs TiDB

| Critère | Aiven MySQL | TiDB Cloud |
|---------|-------------|------------|
| **Mise en veille** | ❌ S'endort après inactivité | ✅ Jamais |
| **Prix** | ~$15/mois minimum | Gratuit (Serverless) |
| **Scalabilité** | Manuelle | Automatique |
| **Compatibilité Prisma** | ✅ MySQL | ✅ TiDB (compatible MySQL) |
| **TLS** | ✅ | ✅ |
| **Régions** | Limitées | Multiples |
| **Latence au réveil** | ⚠️ 5-30s | ✅ 0ms |

## 📝 Notes importantes

- **Le fichier `.env`** ne doit jamais être poussé sur GitHub
- **Les secrets TiDB** doivent être gérés dans Vercel (Environment Variables)
- **Le plan Serverless gratuit** de TiDB offre 5 Go de stockage et 50M de requêtes/mois - suffisant pour démarrer
- **Prisma utilise `provider = "mysql"`** - TiDB est 100% compatible avec le protocole MySQL, c'est pourquoi Prisma continue d'utiliser le provider MySQL. Aucun changement de code n'est nécessaire.
- **Prisma 6.5+** fonctionne parfaitement avec TiDB via le provider MySQL (les deux utilisent le même protocole filaire)
