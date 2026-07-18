# API Documentation - KIVOO Backend

## Stack Technique

- **Runtime** : Node.js (v18+)
- **Framework** : Express.js
- **Base de données** : MongoDB avec Mongoose
- **Authentification** : JWT (JSON Web Tokens)
- **Validation** : Joi ou Zod
- **Upload d'images** : Multer + Cloudinary/AWS S3
- **Temps réel** : Socket.io (pour les discussions)
- **Sécurité** : bcrypt (hashage mots de passe), helmet, cors, express-validator

---

## Structure de la Base de Données

### 1. User (Utilisateur)

```javascript
{
  _id: ObjectId,
  email: String (unique, required),
  password: String (required, hashed),
  name: String (required),
  phone: String (required, unique),
  photo: String (URL de la photo de profil),
  location: {
    city: String,
    country: String,
    coordinates: {
      lat: Number,
      lng: Number
    }
  },
  verified: Boolean (default: false),
  rating: Number (default: 0),
  ratingCount: Number (default: 0),
  joinedAt: Date (default: Date.now),
  lastLogin: Date,
  isActive: Boolean (default: true),
  socialProviders: [{
    provider: String (google, facebook),
    providerId: String,
    email: String
  }],
  preferences: {
    notifications: Boolean (default: true),
    language: String (default: 'fr')
  }
}
```

### 2. Category (Catégorie)

```javascript
{
  _id: ObjectId,
  name: String (required, unique),
  icon: String (emoji ou nom d'icône),
  color: String (code couleur hex),
  parentCategory: ObjectId (référence à Category, pour sous-catégories),
  isActive: Boolean (default: true),
  createdAt: Date
}
```

**Catégories par défaut :**
- Véhicules
- Immobilier
- Téléphones
- Emplois
- Mode
- Meubles
- Animaux
- Services

### 3. Item (Annonce/Article)

```javascript
{
  _id: ObjectId,
  title: String (required),
  description: String (required),
  price: Number (required),
  priceType: String (fixed, negotiable, rent, auction),
  category: ObjectId (référence à Category, required),
  subcategory: ObjectId (référence à Category, optionnel),
  seller: ObjectId (référence à User, required),
  location: {
    city: String,
    country: String,
    address: String,
    coordinates: {
      lat: Number,
      lng: Number
    }
  },
  condition: String (new, like_new, good, fair, used),
  brand: String,
  model: String,
  year: Number,
  images: [String] (URLs des photos),
  featured: Boolean (default: false),
  featuredUntil: Date,
  status: String (active, sold, expired, pending),
  views: Number (default: 0),
  likes: Number (default: 0),
  boostLevel: Number (default: 0),
  boostUntil: Date,
  tags: [String],
  specifications: {
    // Champs dynamiques selon la catégorie
    mileage: Number, // pour véhicules
    bedrooms: Number, // pour immobilier
    storage: String, // pour téléphones
    // etc.
  },
  createdAt: Date,
  updatedAt: Date,
  expiresAt: Date (généralement 30 jours après création)
}
```

### 4. Favorite (Favoris)

```javascript
{
  _id: ObjectId,
  user: ObjectId (référence à User, required),
  item: ObjectId (référence à Item, required),
  createdAt: Date,
  
  // Index unique composé de user et item
  unique: true
}
```

### 5. Conversation (Conversation)

```javascript
{
  _id: ObjectId,
  participants: [ObjectId] (références à User, min: 2),
  item: ObjectId (référence à Item, optionnel - conversation liée à une annonce),
  lastMessage: {
    content: String,
    sender: ObjectId (référence à User),
    sentAt: Date
  },
  unreadCount: {
    [userId]: Number
  },
  createdAt: Date,
  updatedAt: Date
}
```

### 6. Message (Message)

```javascript
{
  _id: ObjectId,
  conversation: ObjectId (référence à Conversation, required),
  sender: ObjectId (référence à User, required),
  content: String (required),
  type: String (text, image, location, contact),
  attachments: [{
    type: String,
    url: String,
    name: String
  }],
  read: Boolean (default: false),
  readAt: Date,
  createdAt: Date
}
```

### 7. Review (Avis/Évaluation)

```javascript
{
  _id: ObjectId,
  reviewer: ObjectId (référence à User, required),
  reviewed: ObjectId (référence à User, required),
  item: ObjectId (référence à Item, optionnel),
  rating: Number (1-5, required),
  comment: String,
  createdAt: Date,
  
  // Un utilisateur ne peut laisser qu'un avis par transaction
  unique: true
}
```

### 8. Notification (Notification)

```javascript
{
  _id: ObjectId,
  user: ObjectId (référence à User, required),
  type: String (message, favorite, price_drop, new_item, system),
  title: String (required),
  message: String (required),
  data: {
    itemId: ObjectId,
    conversationId: ObjectId,
    userId: ObjectId
  },
  read: Boolean (default: false),
  createdAt: Date
}
```

### 9. Report (Signalement)

```javascript
{
  _id: ObjectId,
  reporter: ObjectId (référence à User, required),
  reportedItem: ObjectId (référence à Item, required),
  reportedUser: ObjectId (référence à User, required),
  reason: String (required),
  description: String,
  status: String (pending, reviewed, resolved, dismissed),
  reviewedBy: ObjectId (référence à User, admin),
  reviewedAt: Date,
  createdAt: Date
}
```

---

## Endpoints API - Authentification

### POST /api/auth/register
Inscription d'un nouvel utilisateur

**Request Body:**
```json
{
  "name": "Jean Dupont",
  "email": "jean@example.com",
  "phone": "+221771234567",
  "password": "MotDePasse123!",
  "location": {
    "city": "Dakar",
    "country": "Sénégal"
  }
}
```

**Response (201):**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "64a1b2c3d4e5f6789",
      "email": "jean@example.com",
      "name": "Jean Dupont",
      "phone": "+221771234567",
      "photo": null,
      "verified": false
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

### POST /api/auth/login
Connexion utilisateur

**Request Body:**
```json
{
  "email": "jean@example.com",
  "password": "MotDePasse123!"
}
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "64a1b2c3d4e5f6789",
      "email": "jean@example.com",
      "name": "Jean Dupont",
      "phone": "+221771234567",
      "photo": "https://res.cloudinary.com/...",
      "verified": true,
      "rating": 4.5,
      "ratingCount": 12
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

### POST /api/auth/social-login
Connexion via Google/Facebook

**Request Body:**
```json
{
  "provider": "google",
  "providerId": "123456789",
  "email": "jean@gmail.com",
  "name": "Jean Dupont",
  "photo": "https://..."
}
```

### POST /api/auth/refresh-token
Rafraîchir le token JWT

**Headers:**
```
Authorization: Bearer <refresh_token>
```

### POST /api/auth/forgot-password
Demande de réinitialisation de mot de passe

**Request Body:**
```json
{
  "email": "jean@example.com"
}
```

### POST /api/auth/reset-password
Réinitialisation du mot de passe

**Request Body:**
```json
{
  "token": "reset_token_from_email",
  "newPassword": "NouveauMotDePasse123!"
}
```

### GET /api/auth/me
Récupérer le profil de l'utilisateur connecté

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "64a1b2c3d4e5f6789",
    "email": "jean@example.com",
    "name": "Jean Dupont",
    "phone": "+221771234567",
    "photo": "https://res.cloudinary.com/...",
    "location": {
      "city": "Dakar",
      "country": "Sénégal"
    },
    "verified": true,
    "rating": 4.5,
    "ratingCount": 12,
    "joinedAt": "2024-01-15T10:30:00Z"
  }
}
```

### PUT /api/auth/profile
Mettre à jour le profil

**Headers:**
```
Authorization: Bearer <access_token>
```

**Request Body:**
```json
{
  "name": "Jean Dupont Modifié",
  "phone": "+221779876543",
  "location": {
    "city": "Abidjan",
    "country": "Côte d'Ivoire"
  }
}
```

---

## Endpoints API - Items (Annonces)

### GET /api/items
Récupérer les annonces avec pagination et filtres

**Query Parameters:**
- `page` (number, default: 1)
- `limit` (number, default: 20)
- `category` (string, ID de catégorie)
- `location` (string, ville)
- `minPrice` (number)
- `maxPrice` (number)
- `condition` (string: new, like_new, good, fair, used)
- `search` (string, recherche dans titre/description)
- `sort` (string: newest, price_asc, price_desc, popular)
- `featured` (boolean, default: false)

**Response (200):**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "64b2c3d4e5f678901",
        "title": "iPhone 15 Pro Max — 256GB",
        "description": "Téléphone neuf, débloqué...",
        "price": 950000,
        "priceType": "fixed",
        "category": {
          "id": 3,
          "name": "Téléphones",
          "icon": "📱",
          "color": "#22c55e"
        },
        "seller": {
          "id": "64a1b2c3d4e5f6789",
          "name": "Jean Dupont",
          "photo": "https://...",
          "rating": 4.5,
          "verified": true
        },
        "location": {
          "city": "Dakar",
          "country": "Sénégal"
        },
        "condition": "Neuf",
        "images": [
          "https://res.cloudinary.com/...",
          "https://res.cloudinary.com/..."
        ],
        "featured": true,
        "status": "active",
        "views": 245,
        "likes": 18,
        "createdAt": "2024-07-15T08:30:00Z"
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 10,
      "totalItems": 198,
      "hasNext": true,
      "hasPrev": false
    }
  }
}
```

### GET /api/items/trending
Récupérer les annonces tendances/populaires

**Query Parameters:**
- `limit` (number, default: 10)

### GET /api/items/featured
Récupérer les annonces en vedette

**Query Parameters:**
- `limit` (number, default: 10)

### GET /api/items/:id
Récupérer une annonce spécifique

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "64b2c3d4e5f678901",
    "title": "iPhone 15 Pro Max — 256GB",
    "description": "Téléphone neuf...",
    "price": 950000,
    "priceType": "fixed",
    "category": { ... },
    "seller": { ... },
    "location": { ... },
    "condition": "Neuf",
    "images": [ ... ],
    "featured": true,
    "status": "active",
    "views": 245,
    "likes": 18,
    "specifications": {
      "storage": "256GB",
      "color": "Natural Titanium",
      "battery": "100%"
    },
    "createdAt": "2024-07-15T08:30:00Z"
  }
}
```

### POST /api/items
Créer une nouvelle annonce

**Headers:**
```
Authorization: Bearer <access_token>
Content-Type: multipart/form-data
```

**Request Body (FormData):**
```
title: "iPhone 15 Pro Max"
description: "Téléphone neuf..."
price: 950000
priceType: "fixed"
category: "64c3d4e5f678901234"
condition: "new"
location.city: "Dakar"
location.country: "Sénégal"
images: [File1, File2, File3]
specifications.storage: "256GB"
specifications.color: "Natural Titanium"
```

**Response (201):**
```json
{
  "success": true,
  "data": {
    "id": "64b2c3d4e5f678901",
    "title": "iPhone 15 Pro Max",
    ...
  }
}
```

### PUT /api/items/:id
Modifier une annonce

**Headers:**
```
Authorization: Bearer <access_token>
```

### DELETE /api/items/:id
Supprimer une annonce

**Headers:**
```
Authorization: Bearer <access_token>
```

### POST /api/items/:id/boost
Booster une annonce (mettre en avant)

**Headers:**
```
Authorization: Bearer <access_token>
```

**Request Body:**
```json
{
  "duration": 7 // jours
}
```

---

## Endpoints API - Catégories

### GET /api/categories
Récupérer toutes les catégories

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Véhicules",
      "icon": "🚗",
      "color": "#ff6b35",
      "subcategories": [
        {
          "id": 11,
          "name": "Voitures",
          "icon": "🚗"
        },
        {
          "id": 12,
          "name": "Motos",
          "icon": "🏍️"
        }
      ]
    },
    {
      "id": 2,
      "name": "Immobilier",
      "icon": "🏠",
      "color": "#4f8ef7"
    }
  ]
}
```

### GET /api/categories/:id
Récupérer une catégorie spécifique

---

## Endpoints API - Favoris

### GET /api/favorites
Récupérer les favoris de l'utilisateur

**Headers:**
```
Authorization: Bearer <access_token>
```

**Query Parameters:**
- `page` (number)
- `limit` (number)

**Response (200):**
```json
{
  "success": true,
  "data": {
    "favorites": [
      {
        "id": "64d4e5f6789012345",
        "item": {
          "id": "64b2c3d4e5f678901",
          "title": "iPhone 15 Pro Max",
          "price": 950000,
          "images": ["https://..."],
          "condition": "Neuf",
          "seller": {
            "name": "Jean Dupont",
            "rating": 4.5
          }
        },
        "createdAt": "2024-07-15T10:00:00Z"
      }
    ],
    "pagination": { ... }
  }
}
```

### POST /api/favorites/:itemId
Ajouter un article aux favoris

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response (201):**
```json
{
  "success": true,
  "message": "Article ajouté aux favoris"
}
```

### DELETE /api/favorites/:itemId
Retirer un article des favoris

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response (200):**
```json
{
  "success": true,
  "message": "Article retiré des favoris"
}
```

### GET /api/favorites/check/:itemId
Vérifier si un article est dans les favoris

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "isFavorite": true
  }
}
```

---

## Endpoints API - Discussions (Messagerie)

### GET /api/conversations
Récupérer les conversations de l'utilisateur

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": "64e5f678901234567",
      "participants": [
        {
          "id": "64a1b2c3d4e5f6789",
          "name": "Jean Dupont",
          "photo": "https://..."
        }
      ],
      "item": {
        "id": "64b2c3d4e5f678901",
        "title": "iPhone 15 Pro Max",
        "price": 950000,
        "image": "https://..."
      },
      "lastMessage": {
        "content": "Est-ce que le prix est négociable ?",
        "sender": {
          "id": "64f6g7h8i9j0k1234",
          "name": "Marie Koné"
        },
        "sentAt": "2024-07-15T14:30:00Z"
      },
      "unreadCount": 2,
      "updatedAt": "2024-07-15T14:30:00Z"
    }
  ]
}
```

### GET /api/conversations/:id/messages
Récupérer les messages d'une conversation

**Headers:**
```
Authorization: Bearer <access_token>
```

**Query Parameters:**
- `page` (number)
- `limit` (number, default: 50)

**Response (200):**
```json
{
  "success": true,
  "data": {
    "messages": [
      {
        "id": "64g7h8i9j0k123456",
        "sender": {
          "id": "64f6g7h8i9j0k1234",
          "name": "Marie Koné",
          "photo": "https://..."
        },
        "content": "Bonjour, est-ce que le téléphone est toujours disponible ?",
        "type": "text",
        "read": true,
        "createdAt": "2024-07-15T14:00:00Z"
      },
      {
        "id": "64h8i9j0k1234567",
        "sender": {
          "id": "64a1b2c3d4e5f6789",
          "name": "Jean Dupont"
        },
        "content": "Oui, il est toujours disponible",
        "type": "text",
        "read": true,
        "createdAt": "2024-07-15T14:05:00Z"
      }
    ],
    "pagination": { ... }
  }
}
```

### POST /api/conversations
Créer une nouvelle conversation

**Headers:**
```
Authorization: Bearer <access_token>
```

**Request Body:**
```json
{
  "participantId": "64f6g7h8i9j0k1234",
  "itemId": "64b2c3d4e5f678901",
  "message": "Bonjour, est-ce que le téléphone est toujours disponible ?"
}
```

### POST /api/conversations/:id/messages
Envoyer un message

**Headers:**
```
Authorization: Bearer <access_token>
```

**Request Body:**
```json
{
  "content": "Est-ce que le prix est négociable ?",
  "type": "text"
}
```

**Response (201):**
```json
{
  "success": true,
  "data": {
    "id": "64i9j0k1234567890",
    "sender": {
      "id": "64a1b2c3d4e5f6789",
      "name": "Jean Dupont"
    },
    "content": "Est-ce que le prix est négociable ?",
    "type": "text",
    "read": false,
    "createdAt": "2024-07-15T14:30:00Z"
  }
}
```

### PUT /api/conversations/:id/read
Marquer les messages comme lus

**Headers:**
```
Authorization: Bearer <access_token>
```

---

## Endpoints API - Profil Utilisateur

### GET /api/users/:id
Récupérer le profil public d'un utilisateur

**Response (200):**
```json
{
  "success": true,
  "data": {
    "id": "64a1b2c3d4e5f6789",
    "name": "Jean Dupont",
    "photo": "https://res.cloudinary.com/...",
    "location": {
      "city": "Dakar",
      "country": "Sénégal"
    },
    "verified": true,
    "rating": 4.5,
    "ratingCount": 12,
    "joinedAt": "2024-01-15T10:30:00Z",
    "stats": {
      "itemsListed": 23,
      "itemsSold": 15,
      "responseRate": 95,
      "responseTime": "2h"
    }
  }
}
```

### GET /api/users/:id/items
Récupérer les annonces d'un utilisateur

**Query Parameters:**
- `page` (number)
- `limit` (number)
- `status` (string: active, sold, all)

**Response (200):**
```json
{
  "success": true,
  "data": {
    "items": [ ... ],
    "pagination": { ... }
  }
}
```

### GET /api/users/:id/reviews
Récupérer les avis sur un utilisateur

**Query Parameters:**
- `page` (number)
- `limit` (number)

**Response (200):**
```json
{
  "success": true,
  "data": {
    "reviews": [
      {
        "id": "64j0k123456789012",
        "reviewer": {
          "id": "64k1l2m3n4o5p6789",
          "name": "Marie Koné",
          "photo": "https://..."
        },
        "rating": 5,
        "comment": "Vendeur sérieux et rapide, je recommande !",
        "item": {
          "id": "64b2c3d4e5f678901",
          "title": "iPhone 15 Pro Max"
        },
        "createdAt": "2024-07-10T16:00:00Z"
      }
    ],
    "averageRating": 4.5,
    "totalReviews": 12
  }
}
```

---

## Endpoints API - Notifications

### GET /api/notifications
Récupérer les notifications de l'utilisateur

**Headers:**
```
Authorization: Bearer <access_token>
```

**Query Parameters:**
- `page` (number)
- `limit` (number)
- `unreadOnly` (boolean, default: false)

**Response (200):**
```json
{
  "success": true,
  "data": {
    "notifications": [
      {
        "id": "64k1l2m3n4o5p6789",
        "type": "favorite",
        "title": "Nouveau favori",
        "message": "Marie Koné a ajouté votre annonce aux favoris",
        "data": {
          "itemId": "64b2c3d4e5f678901"
        },
        "read": false,
        "createdAt": "2024-07-15T12:00:00Z"
      }
    ],
    "unreadCount": 5
  }
}
```

### PUT /api/notifications/:id/read
Marquer une notification comme lue

**Headers:**
```
Authorization: Bearer <access_token>
```

### PUT /api/notifications/read-all
Marquer toutes les notifications comme lues

**Headers:**
```
Authorization: Bearer <access_token>
```

---

## Endpoints API - Upload

### POST /api/upload/image
Uploader une image

**Headers:**
```
Authorization: Bearer <access_token>
Content-Type: multipart/form-data
```

**Request Body:**
```
image: File
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "url": "https://res.cloudinary.com/...",
    "publicId": "kivoo/items/64b2c3d4e5f678901"
  }
}
```

### POST /api/upload/images
Uploader plusieurs images

**Headers:**
```
Authorization: Bearer <access_token>
Content-Type: multipart/form-data
```

**Request Body:**
```
images: [File1, File2, File3]
```

---

## Endpoints API - Signalements

### POST /api/reports
Signaler un contenu inapproprié

**Headers:**
```
Authorization: Bearer <access_token>
```

**Request Body:**
```json
{
  "reportedItemId": "64b2c3d4e5f678901",
  "reportedUserId": "64f6g7h8i9j0k1234",
  "reason": "spam",
  "description": "Cette annonce contient des informations fausses"
}
```

**Reasons disponibles:**
- `spam` - Spam ou contenu commercial abusif
- `fraud` - Fraude ou arnaque
- `inappropriate` - Contenu inapproprié
- `fake` - Fausse annonce
- `other` - Autre

---

## Endpoints API - Admin

### GET /api/admin/stats
Statistiques globales

**Headers:**
```
Authorization: Bearer <admin_token>
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "totalUsers": 15420,
    "totalItems": 89340,
    "totalCategories": 8,
    "activeUsers": 3420,
    "newUsersToday": 45,
    "newItemsToday": 123,
    "revenue": {
      "today": 125000,
      "month": 3450000,
      "total": 12500000
    }
  }
}
```

### GET /api/admin/users
Gestion des utilisateurs

**Query Parameters:**
- `page`, `limit`, `search`, `verified`, `active`

### GET /api/admin/items
Gestion des annonces

**Query Parameters:**
- `page`, `limit`, `status`, `category`, `search`

### PUT /api/admin/items/:id/approve
Approuver une annonce

### PUT /api/admin/items/:id/reject
Rejeter une annonce

**Request Body:**
```json
{
  "reason": "Contenu inapproprié"
}
```

### GET /api/admin/reports
Voir les signalements

### PUT /api/admin/reports/:id/resolve
Résoudre un signalement

---

## WebSocket Events (Socket.io)

### Client → Server

#### join_conversation
Rejoindre une conversation pour recevoir les messages en temps réel

```javascript
socket.emit('join_conversation', { conversationId: '...' });
```

#### send_message
Envoyer un message

```javascript
socket.emit('send_message', {
  conversationId: '...',
  content: 'Bonjour',
  type: 'text'
});
```

#### typing_start
Indiquer que l'utilisateur écrit

```javascript
socket.emit('typing_start', { conversationId: '...' });
```

#### typing_stop
Indiquer que l'utilisateur a arrêté d'écrire

```javascript
socket.emit('typing_stop', { conversationId: '...' });
```

### Server → Client

#### new_message
Nouveau message reçu

```javascript
socket.on('new_message', (message) => {
  console.log('Nouveau message:', message);
});
```

#### user_typing
Un utilisateur est en train d'écrire

```javascript
socket.on('user_typing', (data) => {
  console.log(`${data.userName} est en train d'écrire...`);
});
```

#### user_stop_typing
Un utilisateur a arrêté d'écrire

```javascript
socket.on('user_stop_typing', (data) => {
  console.log(`${data.userName} a arrêté d'écrire`);
});
```

---

## Codes d'Erreur

| Code | Description |
|------|-------------|
| 200 | Succès |
| 201 | Créé avec succès |
| 400 | Requête invalide |
| 401 | Non authentifié |
| 403 | Non autorisé |
| 404 | Ressource non trouvée |
| 409 | Conflit (ex: email déjà utilisé) |
| 422 | Erreur de validation |
| 429 | Trop de requêtes (rate limit) |
| 500 | Erreur serveur |

**Format d'erreur:**
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Erreur de validation des données",
    "details": [
      {
        "field": "email",
        "message": "L'email est requis"
      }
    ]
  }
}
```

---

## Authentification et Sécurité

### Headers requis pour les routes protégées

```
Authorization: Bearer <access_token>
Content-Type: application/json
```

### Rôles utilisateurs

- **user** : Utilisateur standard
- **moderator** : Modérateur
- **admin** : Administrateur

### Rate Limiting

- **Authentification** : 5 requêtes/minute
- **API générale** : 100 requêtes/minute
- **Upload** : 10 requêtes/minute

---

## Variables d'Environnement

```env
# Server
NODE_ENV=development
PORT=5000
API_URL=http://localhost:5000/api

# Database
MONGODB_URI=mongodb://localhost:27017/kivoo
MONGODB_URI_PROD=mongodb+srv://user:pass@cluster.mongodb.net/kivoo

# JWT
JWT_SECRET=your_jwt_secret_key_here
JWT_EXPIRE=7d
JWT_REFRESH_SECRET=your_refresh_secret_key_here
JWT_REFRESH_EXPIRE=30d

# Cloudinary (Upload d'images)
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret

# Socket.io
SOCKET_PORT=5001

# Email (Nodemailer)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your_email@gmail.com
SMTP_PASS=your_app_password

# Frontend
FRONTEND_URL=http://localhost:3000

# Admin
ADMIN_EMAIL=admin@kivoo.com
ADMIN_PASSWORD=secure_admin_password
```

---

## Installation et Démarrage

```bash
# Installation des dépendances
npm install

# Copier le fichier .env.example vers .env
cp .env.example .env

# Configurer les variables d'environnement

# Démarrer en développement
npm run dev

# Démarrer en production
npm start

# Tests
npm test
```

---

## Structure du Projet Backend

```
backend/
├── src/
│   ├── config/
│   │   ├── database.js
│   │   └── cloudinary.js
│   ├── controllers/
│   │   ├── authController.js
│   │   ├── itemController.js
│   │   ├── categoryController.js
│   │   ├── favoriteController.js
│   │   ├── conversationController.js
│   │   ├── userController.js
│   │   └── notificationController.js
│   ├── middleware/
│   │   ├── auth.js
│   │   ├── validation.js
│   │   ├── upload.js
│   │   └── errorHandler.js
│   ├── models/
│   │   ├── User.js
│   │   ├── Item.js
│   │   ├── Category.js
│   │   ├── Favorite.js
│   │   ├── Conversation.js
│   │   ├── Message.js
│   │   ├── Review.js
│   │   └── Notification.js
│   ├── routes/
│   │   ├── auth.js
│   │   ├── items.js
│   │   ├── categories.js
│   │   ├── favorites.js
│   │   ├── conversations.js
│   │   ├── users.js
│   │   └── notifications.js
│   ├── services/
│   │   ├── emailService.js
│   │   ├── pushNotificationService.js
│   │   └── recommendationService.js
│   ├── utils/
│   │   ├── helpers.js
│   │   └── validators.js
│   └── app.js
├── tests/
├── .env.example
├── package.json
└── README.md
```

---

## Notes Importantes

1. **Sécurité** : Tous les mots de passe doivent être hashés avec bcrypt (salt rounds: 12)
2. **Validation** : Valider toutes les entrées utilisateur avec Joi/Zod
3. **Pagination** : Toujours implémenter la pagination pour les listes
4. **Cache** : Utiliser Redis pour cacher les données fréquemment accédées (catégories, featured items)
5. **Search** : Implémenter une recherche full-text avec MongoDB Atlas Search ou Elasticsearch
6. **Images** : Utiliser Cloudinary ou AWS S3 pour le stockage d'images avec optimisation automatique
7. **Backup** : Sauvegardes automatiques de la base de données
8. **Monitoring** : Logger toutes les erreurs et utiliser un service de monitoring (Sentry, LogRocket)

---

## Évolutions Futures

- [ ] Système de paiement intégré (Mobile Money, carte bancaire)
- [ ] Système de livraison avec suivi
- [ ] Chatbot pour le support client
- [ ] Système de recommandation intelligent
- [ ] Géolocalisation avancée avec recherche par rayon
- [ ] Système de négociation de prix
- [ ] Abonnements premium pour vendeurs
- [ ] Système de cagnotte/escrow pour les transactions
- [ ] Intégration avec des services de vérification d'identité
- [ ] Analytics avancés pour vendeurs