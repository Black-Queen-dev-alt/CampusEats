# Documentation de l’API CampusEats

API REST de CampusEats, construite avec Node.js 24+, Express 5, TypeScript, Mongoose et MongoDB.

## URL et vérification

| Environnement | URL de base |
|---|---|
| Production | `https://campuseats-nkv4.onrender.com` |
| Local | `http://localhost:3000` |

Il n’y a pas de préfixe `/api`. La route de santé publique est [`GET /health`](https://campuseats-nkv4.onrender.com/health). Elle renvoie par exemple :

```json
{
  "status": "ok",
  "timestamp": "2026-11-25T21:45:48.315Z"
}
```

Le service de production utilise le forfait gratuit Render et peut se mettre en veille après une période d’inactivité. La première requête peut alors prendre plus de temps.

## Conventions générales

- Les corps des requêtes et les réponses utilisent JSON, sauf la déconnexion qui renvoie `204 No Content`.
- Les identifiants MongoDB sont des chaînes ObjectId de 24 caractères hexadécimaux.
- Les routes protégées requièrent `Authorization: Bearer <accessToken>`.
- Les rôles utilisés sont `etudiant`, `personnel` et `admin`.
- Les paramètres invalides ou les champs inconnus sont validés/nettoyés par l’API.
- La pagination utilise `page` (défaut `1`) et `limit` (défaut `20`, maximum `50`).

### Réponses

Les succès contenant une ressource suivent généralement cette forme :

```json
{
  "success": true,
  "data": {}
}
```

Les listes renvoient un tableau dans `data` et des métadonnées `pagination`. Les erreurs suivent ce format :

```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Description de l’erreur",
    "details": null
  }
}
```

Selon l’erreur, l’API peut renvoyer les statuts HTTP `400`, `401`, `403`, `404`, `409`, `413`, `422` ou `500`.

## Authentification

| Méthode | Route | Accès | Description |
|---|---|---|---|
| `POST` | `/auth/register` | Public | Créer un compte étudiant |
| `POST` | `/auth/login` | Public | Se connecter |
| `POST` | `/auth/refresh` | Public | Renouveler les jetons; le refresh token est à usage unique |
| `POST` | `/auth/logout` | Public | Révoquer le refresh token fourni |

### Inscription — `POST /auth/register`

```json
{
  "email": "etudiant@universite.edu",
  "password": "un-mot-de-passe",
  "fullName": "Nom Étudiant",
  "phone": "+000000000"
}
```

`phone` est facultatif. Le mot de passe doit contenir de 8 à 128 caractères.

### Connexion — `POST /auth/login`

```json
{
  "email": "etudiant@universite.edu",
  "password": "un-mot-de-passe"
}
```

La réponse contient les jetons d’accès et de renouvellement dans `data`. Utiliser l’access token comme Bearer pour les routes protégées.

### Renouvellement — `POST /auth/refresh`

```json
{
  "refreshToken": "<refreshToken>"
}
```

Le refresh token est rotatif : utiliser le nouveau jeton retourné et ne pas réutiliser l’ancien.

### Déconnexion — `POST /auth/logout`

```json
{
  "refreshToken": "<refreshToken>"
}
```

Réponse en cas de succès : `204 No Content`.

## Profil et utilisateurs

| Méthode | Route | Accès | Description |
|---|---|---|---|
| `GET` | `/me` | Authentifié | Lire son profil |
| `PATCH` | `/me` | Authentifié | Modifier son nom et/ou son téléphone |
| `POST` | `/admin/users` | Admin | Créer un compte personnel ou administrateur |
| `PATCH` | `/admin/users/:id/status` | Admin | Activer ou suspendre un utilisateur |

### Modifier son profil — `PATCH /me`

Au moins un champ est requis; le rôle ne peut pas être modifié ici.

```json
{
  "fullName": "Nouveau Nom",
  "phone": "+000000000"
}
```

### Créer un membre du personnel — `POST /admin/users`

```json
{
  "email": "personnel@universite.edu",
  "password": "un-mot-de-passe",
  "fullName": "Nom Personnel",
  "role": "personnel",
  "phone": "+000000000"
}
```

`role` vaut `personnel` ou `admin`; `phone` est facultatif.

### Modifier le statut — `PATCH /admin/users/:id/status`

```json
{
  "status": "actif"
}
```

`status` vaut `actif` ou `suspendu`.

## Plats

| Méthode | Route | Accès | Description |
|---|---|---|---|
| `GET` | `/dishes` | Authentifié | Lister les plats actifs, avec pagination et filtres |
| `GET` | `/dishes/:id` | Authentifié | Lire un plat; les plats inactifs sont réservés aux admins |
| `POST` | `/dishes` | Admin | Créer un plat |
| `PATCH` | `/dishes/:id` | Admin | Modifier un ou plusieurs champs |

Filtres disponibles sur `GET /dishes` :

- `category` : `entree`, `plat`, `dessert` ou `boisson`
- `isVegetarian` : `true` ou `false`
- `allergen` : rechercher un allergène
- `search` : recherche textuelle
- `page`, `limit` : pagination

Exemple : `GET /dishes?category=plat&isVegetarian=true&page=1&limit=20`

### Créer un plat — `POST /dishes`

```json
{
  "name": "Salade composée",
  "description": "Salade fraîche avec des légumes de saison.",
  "priceInCents": 2500,
  "category": "entree",
  "photoUrl": null,
  "allergens": [],
  "isVegetarian": true,
  "isActive": true
}
```

`priceInCents` est un entier positif ou nul. `photoUrl` peut être une URL ou `null`. `allergens`, `isVegetarian` et `isActive` ont respectivement pour défaut `[]`, `false` et `true`.

## Menus

| Méthode | Route | Accès | Description |
|---|---|---|---|
| `GET` | `/menus?date=YYYY-MM-DD` | Authentifié | Lire le menu d’une date; la date est facultative |
| `POST` | `/menus` | Admin | Créer un menu |
| `PATCH` | `/menus/:id` | Admin | Modifier la publication et/ou les plats |

Les menus non publiés sont visibles par le personnel et les admins.

### Créer un menu — `POST /menus`

```json
{
  "date": "2026-12-15",
  "items": [
    {
      "dishId": "507f1f77bcf86cd799439011",
      "isAvailable": true,
      "dailyStockLimit": 50
    }
  ],
  "isPublished": true
}
```

`date` doit être une date réelle au format `YYYY-MM-DD`. Le menu doit contenir au moins un plat; un plat ne peut apparaître qu’une seule fois. `dailyStockLimit` est facultatif.

### Modifier un menu — `PATCH /menus/:id`

```json
{
  "isPublished": false
}
```

On peut aussi transmettre `items` pour remplacer la liste des plats. Au moins un champ doit être fourni.

## Créneaux de retrait

| Méthode | Route | Accès | Description |
|---|---|---|---|
| `GET` | `/time-slots?date=YYYY-MM-DD` | Authentifié | Lister les créneaux d’une date |
| `POST` | `/time-slots` | Admin | Créer un créneau |
| `PATCH` | `/time-slots/:id` | Admin | Modifier un créneau |

La date est obligatoire pour la liste. `page` et `limit` sont également disponibles.

### Créer un créneau — `POST /time-slots`

```json
{
  "date": "2026-12-15",
  "startTime": "12:00",
  "endTime": "12:15",
  "capacity": 20
}
```

Les heures sont au format 24 heures `HH:mm`; l’heure de fin doit être après l’heure de début. La capacité doit être comprise entre 1 et 10 000.

## Commandes

| Méthode | Route | Accès | Description |
|---|---|---|---|
| `POST` | `/orders` | Étudiant | Créer une commande |
| `GET` | `/orders` | Étudiant | Consulter son historique paginé |
| `GET` | `/orders/:id` | Étudiant propriétaire | Lire le détail de sa commande |
| `POST` | `/orders/:id/cancel` | Étudiant propriétaire | Annuler sa commande si les règles métier le permettent |
| `GET` | `/time-slots/:id/orders` | Personnel ou admin | Lister les commandes d’un créneau |
| `PATCH` | `/orders/:id/status` | Personnel ou admin | Changer le statut d’une commande |

### Créer une commande — `POST /orders`

```json
{
  "menuId": "507f1f77bcf86cd799439012",
  "slotId": "507f1f77bcf86cd799439013",
  "lines": [
    {
      "dishId": "507f1f77bcf86cd799439011",
      "quantity": 1
    }
  ]
}
```

Une commande doit contenir de 1 à 20 lignes; chaque quantité doit être comprise entre 1 et 20. Un plat ne peut apparaître qu’une seule fois. La capacité du créneau et le stock journalier sont réservés atomiquement.

Chaque ligne conserve aussi le nom et le prix du plat au moment de la commande (`dishName`, `unitPriceInCents`), indépendamment des modifications ultérieures du catalogue. L’historique et le détail renvoient le créneau associé et un booléen `canCancel`, calculé côté serveur selon le statut et l’heure limite d’annulation.

### Filtrer les commandes d’un créneau

`GET /time-slots/:id/orders?page=1&limit=20&status=received`

`status` est facultatif et peut être `received`, `preparing`, `ready`, `withdrawn` ou `cancelled`.

### Modifier le statut — `PATCH /orders/:id/status`

```json
{
  "status": "preparing"
}
```

Statuts acceptés : `received`, `preparing`, `ready`, `withdrawn`, `cancelled`. Les transitions autorisées dépendent des règles métier.

## Appareils et notifications

### Enregistrer un jeton FCM — `POST /devices`

Accessible à tout utilisateur authentifié (étudiant, personnel ou admin).

```json
{
  "fcmToken": "<jeton-fcm>"
}
```

## Exemple avec cURL

```bash
curl -i "https://campuseats-nkv4.onrender.com/health"
```

Exemple de requête authentifiée :

```bash
curl -i "https://campuseats-nkv4.onrender.com/dishes?page=1&limit=20" \
  -H "Authorization: Bearer <accessToken>"
```

## Lancer et tester en local

Depuis le dossier `api`, suivre les étapes du [README](./README.md). Les requêtes d’exemple sont dans [`requests.http`](./requests.http); elles utilisent `localhost` par défaut et peuvent dépendre de données de développement. Ne pas supposer que les comptes ou données de démonstration sont présents dans la base de production.

## Notes de sécurité

- Ne jamais inclure `MONGO_URI`, les secrets JWT, les mots de passe ou `.env` dans cette documentation, le dépôt mobile ou une capture d’écran.
- Les identifiants de production doivent rester configurés dans Render/Atlas et être renouvelés s’ils ont été exposés.
- L’API utilise HTTPS en production. L’URL `/health` ne nécessite pas d’authentification; les autres routes suivent les règles d’accès indiquées ci-dessus.
