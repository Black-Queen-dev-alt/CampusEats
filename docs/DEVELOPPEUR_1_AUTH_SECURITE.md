# 🛡️ DOCUMENTATION TECHNIQUE – DÉVELOPPEUR 1
## Module Authentification, Sécurité & Gestion des Utilisateurs
**Projet :** CampusEats | **Auteur :** Développeur 1 (Team Lead & Sécurité)  
**Stack :** Node.js 24 + Express 5 + Mongoose + TypeScript + Argon2id + Zod

---

## 📌 1. Périmètre et Responsabilités

Le Développeur 1 a la charge du socle technique, de la gestion des identités, des sessions sécurisées et du contrôle d'accès basé sur les rôles (RBAC).

### Fichiers sous sa responsabilité :
```text
api/
├── src/
│   ├── common/
│   │   ├── errors/app-error.ts              # Format unifié des erreurs HTTP
│   │   ├── middlewares/
│   │   │   ├── auth.middleware.ts           # Vérification JWT Bearer + vérification compte actif
│   │   │   ├── role.middleware.ts           # Contrôle d'accès RBAC (etudiant, personnel, admin)
│   │   │   └── validate.middleware.ts       # Validation stricte Zod (body, query, params)
│   │   └── utils/
│   │       ├── hash.ts                      # Hachage Argon2id & SHA-256
│   │       └── jwt.ts                       # Signature et vérification des Access Tokens
│   ├── modules/
│   │   ├── auth/                            # Module d'authentification & sessions
│   │   │   ├── auth.controller.ts
│   │   │   ├── auth.routes.ts
│   │   │   ├── auth.schema.ts
│   │   │   ├── auth.service.ts
│   │   │   └── refreshToken.model.ts        # Sessions avec TTL index MongoDB
│   │   └── users/                           # Module utilisateurs & administration
│   │       ├── user.controller.ts
│   │       ├── user.model.ts
│   │       ├── user.routes.ts
│   │       ├── user.schema.ts
│   │       └── user.service.ts
│   └── types/express.d.ts                   # Typage TypeScript de req.user
└── requests.http                            # Suite de tests des requêtes HTTP
```

---

## 📋 2. Règles de Gestion (RG) Implémentées

| Règle | Description | Implémentation technique |
| :--- | :--- | :--- |
| **RG01** | Un compte est obligatoire pour toute commande. | Middleware `authenticate` requis sur les routes protégées. |
| **RG02** | Rôles stricts : `etudiant`, `personnel`, `admin`. | `POST /auth/register` force le rôle `etudiant`. Seul l'admin crée le personnel. |
| **RG10** | Un utilisateur ne peut pas modifier son propre rôle. | Le schéma Zod de `PATCH /me` exclut strictement le champ `role` (Mass Assignment protection). |
| **RG13** | Un compte suspendu ne peut plus se connecter ni commander. | Vérification dans `login` et dans `auth.middleware.ts`. La suspension révoque immédiatement tous les tokens. |

---

## 🗄️ 3. Modèles de Données MongoDB (Mongoose)

### 3.1. Collection `users`
* **Index unique :** `email` (minuscules, nettoyé des espaces).
* **Sécurité :** Le champ `password` est automatiquement supprimé de la sérialisation JSON (`toJSON.transform`).

```typescript
{
  _id: ObjectId,
  email: String,        // Unique, obligatoire, lowercase
  password: String,     // Haché avec Argon2id
  fullName: String,     // Obligatoire
  phone: String,        // Optionnel
  role: String,         // 'etudiant' | 'personnel' | 'admin' (défaut: 'etudiant')
  status: String,       // 'actif' | 'suspendu' (défaut: 'actif')
  createdAt: Date,
  updatedAt: Date
}
```

### 3.2. Collection `refreshTokens` (Sessions avec rotation)
* **Index TTL :** `{ expiresAt: 1 }, { expireAfterSeconds: 0 }` (MongoDB purge automatiquement les sessions expirées).
* **Hachage du jeton :** La valeur brute du Refresh Token n'est jamais stockée en clair, mais sous forme d'empreinte SHA-256 (`tokenHash`).

```typescript
{
  _id: ObjectId,
  userId: ObjectId,     // Référence vers users
  tokenHash: String,    // SHA-256 du refresh token
  expiresAt: Date,      // Date d'expiration (7 jours)
  revoked: Boolean,     // true lors du logout ou de la rotation
  createdAt: Date,
  updatedAt: Date
}
```

---

## 🌐 4. Tableau Complet des Endpoints

| Méthode | Route | Accès | Description | Code Succès | Codes d'Erreur |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `POST` | `/auth/register` | Public | Inscription étudiante | `201 Created` | `409` (Email déjà pris), `422` (Validation) |
| `POST` | `/auth/login` | Public | Connexion -> `{ accessToken, refreshToken }` | `200 OK` | `401` (Identifiants faux), `403` (Suspendu), `429` (Rate limit) |
| `POST` | `/auth/refresh` | Public | Rotation du Refresh Token | `200 OK` | `401` (Invalide / Expiré / Révoqué) |
| `POST` | `/auth/logout` | Connecté | Révocation de la session en base | `204 No Content` | `401` |
| `GET` | `/me` | Connecté | Profil de l'utilisateur connecté | `200 OK` | `401` |
| `PATCH` | `/me` | Connecté | Mise à jour du nom ou téléphone | `200 OK` | `401`, `422` |
| `POST` | `/admin/users` | **Admin** | Création de comptes personnel / admin | `201 Created` | `401`, `403` (Non admin), `409`, `422` |
| `PATCH` | `/admin/users/:id/status` | **Admin** | Suspension ou réactivation d'un compte | `200 OK` | `401`, `403`, `404` |

---

## 🔒 5. Tableau des Risques OWASP API & Protections Mises en Place

Ce tableau répond directement à l'**exigence du rapport final (Section 5.3)** demandée par le Dr NIKIEMA :

| Risque OWASP API | Menace identifiée | Protection mise en place par le Développeur 1 |
| :--- | :--- | :--- |
| **API1:2023 - Broken Object Level Authorization (BOLA)** | Un utilisateur tente d'accéder aux données d'un autre. | L'endpoint `/me` utilise l'ID extrait du token JWT vérifié (`req.user.userId`), interdisant tout ID arbitraire en paramètre. |
| **API2:2023 - Broken Authentication** | Attaque brute-force sur les mots de passe et vol de session. | - Limitation de débit (`express-rate-limit`, 100 req/15 min sur `/auth`).<br>- Mots de passe chiffrés avec **Argon2id** (résistant aux attaques GPU/ASIC).<br>- Rotation stricte des refresh tokens avec révocation immédiate de l'ancien jeton. |
| **API3:2023 - Broken Object Property Level Authorization (Mass Assignment)** | Un étudiant injecte `"role": "admin"` lors de son inscription ou modification de profil. | Validation par schéma **Zod** : les champs inconnus sont supprimés (`strip`), et le schéma `updateProfileSchema` ignore le champ `role`. |
| **API4:2023 - Unrestricted Resource Consumption (DoS)** | Envoi de requêtes géantes pour saturer la mémoire du serveur. | Limitation de la taille du corps de requête : `express.json({ limit: '10kb' })`. |
| **API5:2023 - Broken Function Level Authorization (BFLA)** | Un étudiant tente d'appeler les routes `/admin/users`. | Middleware `authorize('admin')` qui vérifie le rôle présent dans le jeton signé cryptographiquement et retourne un code HTTP `403 Forbidden`. |

---

## 🧪 6. Procédure de Test (Guide d'Exécution)

### Démarrage :
```bash
cd api
npm run dev
```

### Exécution des tests via `requests.http` :
1. Ouvrir le fichier `api/requests.http` dans VS Code avec l'extension **REST Client**.
2. Exécuter **`POST /auth/register`** : vérification de la création d'un étudiant avec rôle par défaut.
3. Exécuter **`POST /auth/login`** : vérification de la réception de `accessToken` et `refreshToken`.
4. Exécuter **`GET /me`** avec le Bearer token : validation du retour du profil.
5. Exécuter **`POST /admin/users`** avec le compte étudiant : **vérification du rejet avec code `403 Forbidden`**.

---

## 📝 7. Paragraphe Individuel pour le Rapport Final

*(À inclure dans docs/report.pdf - Section 8 "Contributions individuelles")*

> **Contribution du Développeur 1 :**  
> "En tant que responsable de la sécurité et du socle d'authentification, j'ai mis en place l'architecture modulaire de l'API en Express 5 et TypeScript. J'ai conçu le système d'authentification à double jeton (Access Token court de 15 minutes et Refresh Token rotatif stocké haché en base de données avec index d'expiration TTL). J'ai intégré le hachage robuste Argon2id, configuré les middlewares transverses de sécurité (Helmet, Rate Limiting, validation stricte Zod) et implémenté le contrôle d'accès basé sur les rôles (RBAC) pour isoler les privilèges des étudiants, du personnel et des administrateurs conformément aux règles RG01, RG02, RG10 et RG13."
