# CampusEats API

API REST du sujet T1 : Node.js 24+, Express 5, TypeScript, MongoDB et Mongoose.

## Prérequis et lancement

- Node.js 24 ou plus récent et npm.
- MongoDB local ou MongoDB Atlas.
- Firebase est facultatif en local ; il est requis pour envoyer réellement les notifications push.

Dans PowerShell :

```powershell
Copy-Item .env.example .env
npm ci
npm run seed
npm run dev
```

Le seed est idempotent et n’efface pas les données existantes. Il crée les comptes de démonstration ci-dessous uniquement s’ils n’existent pas déjà. Ne les utilisez jamais en production.

| Rôle | Email | Mot de passe |
|---|---|---|
| Admin | `admin@campuseats.univ.edu` | `Admin1234!` |
| Personnel | `staff@campuseats.univ.edu` | `Staff1234!` |
| Étudiant | `student@campuseats.univ.edu` | `Student1234!` |
| Étudiant | `student2@campuseats.univ.edu` | `Student1234!` |

`MONGO_URI`, les deux secrets JWT et les durées des jetons sont validés au démarrage. Ne versionnez jamais `.env` ni une clé Firebase.

## Endpoints

Toutes les réponses d’erreur métier suivent `{ "success": false, "error": { "code", "message", "details" } }`. Les corps, paramètres et filtres de requête sont validés par Zod ; les clés inconnues sont supprimées. Les listes sont paginées (`page`, `limit`, maximum 50).

| Méthode | Chemin | Accès |
|---|---|---|
| `POST` | `/auth/register` | Public, crée un compte étudiant |
| `POST` | `/auth/login` | Public |
| `POST` | `/auth/refresh` | Public, rotation à usage unique |
| `POST` | `/auth/logout` | Public, révoque le refresh token fourni |
| `GET`, `PATCH` | `/me` | Utilisateur authentifié, son propre profil |
| `POST` | `/admin/users` | Admin |
| `PATCH` | `/admin/users/:id/status` | Admin |
| `GET` | `/dishes` | Authentifié, plats actifs ; recherche et filtres |
| `GET` | `/dishes/:id` | Authentifié ; les plats inactifs sont réservés à l’admin |
| `POST`, `PATCH` | `/dishes`, `/dishes/:id` | Admin |
| `GET` | `/menus?date=YYYY-MM-DD` | Authentifié ; menus non publiés visibles par le personnel et l’admin |
| `POST`, `PATCH` | `/menus`, `/menus/:id` | Admin |
| `GET` | `/time-slots?date=YYYY-MM-DD` | Authentifié |
| `POST`, `PATCH` | `/time-slots`, `/time-slots/:id` | Admin |
| `POST`, `GET` | `/orders` | Étudiant ; création et historique personnel |
| `POST` | `/orders/:id/cancel` | Étudiant propriétaire de la commande |
| `GET` | `/time-slots/:id/orders` | Personnel ou admin |
| `PATCH` | `/orders/:id/status` | Personnel ou admin |
| `POST` | `/devices` | Utilisateur authentifié ; enregistre son jeton FCM |
| `GET` | `/health` | Public |

Les commandes réservent atomiquement la capacité du créneau et le stock journalier du menu. Les annulations admissibles libèrent ces réservations.

## Vérification

```powershell
npm run lint
npm run build
npm test
```

Les tests d’intégration de concurrence et d’authentification utilisent des instances MongoDB temporaires isolées. La CI GitHub Actions fournit également MongoDB pour la suite utilisant `MONGO_URI`.

## Documentation de requêtes

Les exemples du client REST VS Code se trouvent dans [`requests.http`](./requests.http).
