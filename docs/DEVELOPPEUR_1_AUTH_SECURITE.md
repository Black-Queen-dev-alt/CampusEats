# 🛡️ DOCUMENTATION TECHNIQUE & EXPLICATION DU CODE – DÉVELOPPEUR 1
## Module Authentification, Sécurité & Gestion des Utilisateurs
**Projet :** CampusEats | **Auteur :** Développeur 1 (Team Lead & Sécurité)  
**Stack :** Node.js 24 + Express 5 + Mongoose + TypeScript + Argon2id + Zod

---

## 📖 TABLE DES MATIÈRES
1. [Vue d'ensemble de l'Architecture](#1-vue-densemble-de-larchitecture)
2. [Explication Détaillée Fichier par Fichier](#2-explication-détaillée-fichier-par-fichier)
   - [2.1. Cryptographie & Hachage (`hash.ts`)](#21-cryptographie--hachage-srccommonutilshashts)
   - [2.2. Gestion des Jetons JWT (`jwt.ts`)](#22-gestion-des-jetons-jwt-srccommonutilsjwtts)
   - [2.3. Modèle Utilisateur (`user.model.ts`)](#23-modèle-utilisateur-srcmodulesusersusermodelts)
   - [2.4. Modèle Refresh Token & Index TTL (`refreshToken.model.ts`)](#24-modèle-refresh-token--index-ttl-srcmodulesauthrefreshtokenmodelts)
   - [2.5. Middleware d'Authentification (`auth.middleware.ts`)](#25-middleware-dauthentification-srccommonmiddlewaresauthmiddlewarets)
   - [2.6. Middleware de Contrôle d'Accès RBAC (`role.middleware.ts`)](#26-middleware-de-contrôle-daccès-rbac-srccommonmiddlewaresrolemiddlewarets)
   - [2.7. Validation Zod (`auth.schema.ts` & `user.schema.ts`)](#27-validation-zod-authschemats--userschemats)
   - [2.8. Logique Métier & Rotation (`auth.service.ts`)](#28-logique-métier--rotation-srcmodulesauthauthservicets)
   - [2.9. Administration & Suspension (`user.service.ts`)](#29-administration--suspension-srcmodulesusersuserservicets)
3. [Tableau des 8 Endpoints & Codes HTTP](#3-tableau-des-8-endpoints--codes-http)
4. [Défenses OWASP API Security](#4-défenses-owasp-api-security)
5. [Questions Pièges du Jury de Soutenance (FAQ)](#5-questions-pièges-du-jury-de-soutenance-faq)

---

## 1. Vue d'ensemble de l'Architecture

Le code du Développeur 1 est organisé selon une **architecture en couches par ressource (Layered Architecture)** conforme à l'exigence **A2** du livret de projet :

```text
Requête HTTP Client
       │
       ▼
[Middlewares de Sécurité] ──► (Helmet, Rate Limiter, Express.json 10kb)
       │
       ▼
[Routes (auth.routes.ts)] ──► Définition des endpoints et injection des middlewares
       │
       ▼
[Validation Zod] ───────────► Vérifie le format, rejette les champs inconnus (422)
       │
       ▼
[Contrôleur (Controller)] ──► Récupère req.body/params, délègue au service, répond en JSON
       │
       ▼
[Service Métier] ───────────► Règles RG01, RG02, RG10, RG13, hachage, rotation des jetons
       │
       ▼
[Modèles Mongoose] ─────────► Communication sécurisée avec MongoDB Atlas / Local
```

---

## 2. Explication Détaillée Fichier par Fichier

---

### 2.1. Cryptographie & Hachage (`src/common/utils/hash.ts`)

Ce fichier centralise toutes les fonctions cryptographiques pour ne jamais manipuler de mots de passe en clair.

#### Le code :
```typescript
import argon2 from 'argon2';
import crypto from 'crypto';

export async function hashPassword(password: string): Promise<string> {
  return argon2.hash(password, {
    type: argon2.argon2id,
    memoryCost: 2 ** 16, // 64 Mo de RAM
    timeCost: 3,         // 3 itérations
    parallelism: 1,
  });
}

export async function verifyPassword(hash: string, plain: string): Promise<boolean> {
  try {
    return await argon2.verify(hash, plain);
  } catch {
    return false;
  }
}

export function hashToken(token: string): string {
  return crypto.createHash('sha256').update(token).digest('hex');
}

export function generateRandomToken(): string {
  return crypto.randomBytes(40).toString('hex');
}
```

#### 🔍 Explications clés pour la soutenance :
1. **Pourquoi Argon2id et pas MD5 ou simple SHA-256 ?**  
   Argon2id est le vainqueur de la *Password Hashing Competition*. Contrairement aux algorithmes classiques, il est **memory-hard** : il oblige l'attaquant à allouer 64 Mo de mémoire vive pour tester une seule tentative. Cela rend les attaques massives par cartes graphiques (GPU) ou puces dédiées (ASIC) techniquement et financièrement impossibles.
2. **Pourquoi `hashToken` avec SHA-256 ?**  
   Le livret impose : *"rotating refresh token stored hashed"*. Si un pirate parvient à lire la base MongoDB, il ne verra que des empreintes SHA-256 de refresh tokens et ne pourra **en aucun cas** les utiliser pour voler la session d'un utilisateur.
3. **Pourquoi `crypto.randomBytes(40)` ?**  
   Génère 40 octets d'aléa cryptographique pur issu du système d'exploitation, impossible à prédire par un algorithme.

---

### 2.2. Gestion des Jetons JWT (`src/common/utils/jwt.ts`)

Ce fichier gère l'émission et le contrôle des jetons d'accès (Access Tokens).

#### Le code :
```typescript
export interface TokenPayload {
  userId: string;
  role: 'etudiant' | 'personnel' | 'admin';
  email: string;
}

export function signAccessToken(payload: TokenPayload): string {
  return jwt.sign(payload, env.JWT_ACCESS_SECRET, {
    expiresIn: env.ACCESS_TOKEN_TTL as jwt.SignOptions['expiresIn'], // "15m"
  });
}

export function verifyAccessToken(token: string): TokenPayload {
  try {
    return jwt.verify(token, env.JWT_ACCESS_SECRET) as TokenPayload;
  } catch (error) {
    if (error instanceof jwt.TokenExpiredError) {
      throw AppError.unauthorized('Le jeton d\'accès a expiré.');
    }
    throw AppError.unauthorized('Jeton d\'accès invalide.');
  }
}
```

#### 🔍 Explications clés :
* **Que contient le payload du JWT ?**  
  Uniquement `userId`, `role` et `email`. **Jamais d'information sensible** (pas de mot de passe), car un JWT est encodé en Base64 et peut être décodé par n'importe qui.
* **Pourquoi une durée de vie courte de 15 minutes (`15m`) ?**  
  Si un pirate intercepte le jeton d'accès sur le réseau, il ne sera utilisable que pendant quelques minutes au maximum. Au-delà, l'application mobile doit utiliser le Refresh Token pour obtenir un nouveau jeton.

---

### 2.3. Modèle Utilisateur (`src/modules/users/user.model.ts`)

Définit la structure d'un compte utilisateur en base de données.

#### Le code :
```typescript
const UserSchema = new Schema<IUser>(
  {
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
      index: true,
    },
    password: { type: String, required: true },
    fullName: { type: String, required: true, trim: true },
    role: {
      type: String,
      enum: ['etudiant', 'personnel', 'admin'],
      default: 'etudiant',
      required: true,
    },
    status: {
      type: String,
      enum: ['actif', 'suspendu'],
      default: 'actif',
      required: true,
    },
    phone: { type: String, trim: true },
  },
  {
    timestamps: true,
    toJSON: {
      transform: (_doc, ret: Record<string, any>) => {
        delete ret.password;
        delete ret.__v;
        ret.id = ret._id;
        delete ret._id;
        return ret;
      },
    },
  }
);
```

#### 🔍 Explications clés :
* **`toJSON.transform` (Sécurité par défaut) :**  
  Chaque fois qu'un document `User` est converti en JSON pour être envoyé au client, Mongoose supprime automatiquement le champ `password`. Il est donc **techniquement impossible** qu'un mot de passe haché fuite dans une réponse de l'API.
* **Index unique sur `email` :**  
  Empêche physiquement au niveau du moteur MongoDB d'avoir deux utilisateurs avec la même adresse email.
* **`lowercase: true` et `trim: true` :**  
  Nettoie l'email (`Thomas@Univ.fr ` devient `thomas@univ.fr`) pour éviter les doublons accidentels.

---

### 2.4. Modèle Refresh Token & Index TTL (`src/modules/auth/refreshToken.model.ts`)

Gère la persistance des sessions utilisateurs et leur expiration automatique.

#### Le code :
```typescript
const RefreshTokenSchema = new Schema<IRefreshToken>(
  {
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    tokenHash: { type: String, required: true, index: true },
    expiresAt: { type: Date, required: true },
    revoked: { type: Boolean, default: false },
  },
  { timestamps: true }
);

// Index TTL (Time-To-Live)
RefreshTokenSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });
```

#### 🔍 Explications clés :
* **Qu'est-ce que l'index TTL (`expireAfterSeconds: 0`) ?**  
  C'est une fonctionnalité native de MongoDB. Dès que l'heure actuelle dépasse la valeur stockée dans `expiresAt` (par exemple après 7 jours), **MongoDB supprime lui-même la ligne en arrière-plan**. Pas besoin d'écrire un script de nettoyage ou un cron job !
* **Pourquoi le champ `revoked: boolean` ?**  
  Lorsqu'un utilisateur se déconnecte (`logout`), on passe `revoked` à `true`. Ainsi, même si le jeton n'a pas encore atteint sa date d'expiration physique, le serveur sait qu'il a été révoqué volontairement et refuse toute nouvelle demande.

---

### 2.5. Middleware d'Authentification (`src/common/middlewares/auth.middleware.ts`)

Ce middleware intercepte chaque requête vers une route protégée.

#### Le code :
```typescript
export async function authenticate(req: Request, _res: Response, next: NextFunction) {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw AppError.unauthorized('Jeton d\'authentification manquant ou malformé.');
    }

    const token = authHeader.split(' ')[1];
    const payload = verifyAccessToken(token);

    // Vérifier l'état réel du compte en base (RG13)
    const user = await User.findById(payload.userId);
    if (!user) throw AppError.unauthorized('Utilisateur introuvable.');

    if (user.status === 'suspendu') {
      throw AppError.forbidden('Votre compte a été suspendu par un administrateur.');
    }

    req.user = {
      userId: user._id.toString(),
      role: user.role,
      email: user.email,
    };

    next();
  } catch (error) {
    next(error);
  }
}
```

#### 🔍 Explication du flux de contrôle :
1. Vérifie si l'en-tête `Authorization: Bearer <token>` existe. Sinon ➔ **401 Unauthorized**.
2. Vérifie la signature cryptographique et la date d'expiration du jeton avec `verifyAccessToken`.
3. Interroge la base de données : si un administrateur a passé le compte au statut **`suspendu`** il y a 2 secondes, le token est immédiatement refusé avec une erreur **403 Forbidden** (Règle RG13).
4. Injecte les informations certifiées dans `req.user` pour que les contrôleurs suivants sachent avec certitude qui appelle l'API.

---

### 2.6. Middleware de Contrôle d'Accès RBAC (`src/common/middlewares/role.middleware.ts`)

Implémente le contrôle d'accès basé sur les rôles (*Role-Based Access Control*).

#### Le code :
```typescript
export function authorize(...allowedRoles: UserRole[]) {
  return (req: Request, _res: Response, next: NextFunction) => {
    if (!req.user) {
      return next(AppError.unauthorized('Authentification requise.'));
    }

    if (!allowedRoles.includes(req.user.role)) {
      return next(
        AppError.forbidden(
          `Accès interdit : cette ressource nécessite le rôle ${allowedRoles.join(' ou ')}.`
        )
      );
    }

    next();
  };
}
```

#### 🔍 Comment ce code est utilisé sur les routes ?
* Pour réserver une route à l'administrateur seul :
  ```typescript
  userRoutes.post('/admin/users', authenticate, authorize('admin'), UserController.createStaff);
  ```
* Si un étudiant se connecte et tente d'appeler cette route, `allowedRoles.includes('etudiant')` vaut `false` ➔ le middleware renvoie immédiatement une erreur **`403 Forbidden`** sans même exécuter le contrôleur.

---

### 2.7. Validation Zod (`src/modules/auth/auth.schema.ts` & `src/modules/users/user.schema.ts`)

Garantit l'intégrité des données avant qu'elles n'atteignent les services (Exigence A4).

#### Le code :
```typescript
export const registerSchema = z.object({
  email: z.string().email('Format email invalide').toLowerCase().trim(),
  password: z.string().min(6, 'Mot de passe de 6 caractères minimum'),
  fullName: z.string().min(2, 'Nom complet requis').trim(),
  phone: z.string().optional(),
});

// RG10 : Aucun champ "role" n'est présent ici !
export const updateProfileSchema = z.object({
  fullName: z.string().min(2).optional(),
  phone: z.string().optional(),
});
```

#### 🔍 Protection contre l'attaque *Mass Assignment* (RG10) :
Si un étudiant malveillant envoie une requête :
```json
{
  "fullName": "Thomas",
  "role": "admin"
}
```
Le schéma Zod va parser la requête et **supprimer silencieusement le champ `role`**. L'étudiant ne peut donc en aucun cas s'auto-promouvoir administrateur.

---

### 2.8. Logique Métier & Rotation des Jetons (`src/modules/auth/auth.service.ts`)

C'est le cœur métier de l'authentification. Il contient l'algorithme de **rotation des Refresh Tokens** imposé par l'exigence **A6**.

#### Le code du mécanisme de rotation :
```typescript
static async refresh(rawRefreshToken: string) {
  // 1. Calculer l'empreinte SHA-256 du jeton reçu
  const tokenHash = hashToken(rawRefreshToken);
  
  // 2. Chercher en base si ce jeton existe, s'il n'est pas révoqué et s'il n'est pas expiré
  const storedToken = await RefreshToken.findOne({ tokenHash });

  if (!storedToken || storedToken.revoked || storedToken.expiresAt < new Date()) {
    throw AppError.unauthorized('Jeton de rafraîchissement invalide ou expiré.');
  }

  // 3. ROTATION : Révoquer IMMÉDIATEMENT l'ancien jeton (Usage unique !)
  storedToken.revoked = true;
  await storedToken.save();

  // 4. Vérifier que l'utilisateur n'a pas été suspendu entre temps
  const user = await User.findById(storedToken.userId);
  if (!user || user.status === 'suspendu') {
    throw AppError.unauthorized('Session révoquée ou utilisateur inactif.');
  }

  // 5. Émettre une NOUVELLE paire complète (Nouveau Access Token + Nouveau Refresh Token)
  return this.createSession(user);
}
```

#### 🔍 Pourquoi la rotation est-elle si importante ?
* Un Refresh Token ne sert qu'**une seule et unique fois**.
* Si un pirate intercepte un Refresh Token et tente de l'utiliser après l'utilisateur légitime, le serveur constate que `storedToken.revoked === true` et rejette la requête immédiatement.

---

### 2.9. Administration & Suspension (`src/modules/users/user.service.ts`)

Gère la mise à jour des comptes et l'invalidation des sessions.

#### Le code :
```typescript
static async updateUserStatus(userId: string, dto: UpdateUserStatusDTO) {
  const user = await User.findByIdAndUpdate(userId, { status: dto.status }, { new: true });
  if (!user) throw AppError.notFound('Utilisateur introuvable.');

  // RG13 : Si le compte est suspendu, révoquer TOUTES ses sessions actives
  if (dto.status === 'suspendu') {
    await RefreshToken.updateMany({ userId: user._id }, { revoked: true });
  }

  return user;
}
```

#### 🔍 Que se passe-t-il quand un admin suspend un compte ?
1. Le statut passe à `'suspendu'`.
2. La commande `RefreshToken.updateMany(..., { revoked: true })` invalide instantanément tous les téléphones ou navigateurs connectés à ce compte. L'utilisateur est expulsé immédiatement.

---

## 3. Tableau des 8 Endpoints & Codes HTTP

| Méthode | Route | Accès | Description | Succès | Erreurs gérées |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `POST` | `/auth/register` | Public | Inscription (crée uniquement le rôle `etudiant`) | `201 Created` | `409` (Email déjà pris), `422` (Validation Zod) |
| `POST` | `/auth/login` | Public | Connexion -> `{ accessToken, refreshToken }` | `200 OK` | `401` (Faux identifiants), `403` (Compte suspendu), `429` (Trop de requêtes) |
| `POST` | `/auth/refresh` | Public | Rotation du Refresh Token -> Nouvelle paire | `200 OK` | `401` (Expiré ou révoqué) |
| `POST` | `/auth/logout` | Connecté | Déconnexion (révoque la session active) | `204 No Content` | `401` |
| `GET` | `/me` | Connecté | Profil de l'utilisateur connecté | `200 OK` | `401` |
| `PATCH` | `/me` | Connecté | Modification nom/téléphone (rôle protégé) | `200 OK` | `401`, `422` |
| `POST` | `/admin/users` | **Admin** | Création de comptes personnel / admin | `201 Created` | `401`, `403` (Étudiant bloqué), `409`, `422` |
| `PATCH` | `/admin/users/:id/status` | **Admin** | Suspension ou réactivation d'un compte | `200 OK` | `401`, `403`, `404` |

---

## 4. Défenses OWASP API Security

Ce tableau est exigé dans le rapport final (Section 5.3 du cours) :

| Risque OWASP API | Menace | Protection mise en place dans votre code |
| :--- | :--- | :--- |
| **API1 - BOLA** (Accès aux données d'un tiers) | Un étudiant tente de lire le profil d'un autre via `/me`. | Pas d'ID dans l'URL. L'identité est extraite du token JWT infalsifiable (`req.user.userId`). |
| **API2 - Broken Auth** (Vol de session / Brute force) | Attaque par dictionnaire sur les mots de passe. | `express-rate-limit` (100 req/15 min) + hachage lourd **Argon2id** + rotation des refresh tokens. |
| **API3 - Mass Assignment** (Auto-attribution de rôle) | L'étudiant injecte `{"role": "admin"}` dans `PATCH /me`. | Schéma Zod strict qui supprime tout champ non autorisé (`role` absent du schéma). |
| **API4 - DoS** (Saturation mémoire) | Envoi d'un payload JSON géant pour crasher Node.js. | Middleware global : `express.json({ limit: '10kb' })`. |
| **API5 - BFLA** (Appel de fonctions admin) | Un étudiant appelle `POST /admin/users`. | Middleware `authorize('admin')` qui bloque l'appel et retourne un code `403 Forbidden`. |

---

## 5. Questions Pièges du Jury de Soutenance (FAQ)

Voici les questions exactes que le Dr NIKIEMA ou le jury peut vous poser sur votre partie :

### ❓ Question 1 : *"Ouvre le fichier qui rafraîchit le token. Que se passe-t-il si un utilisateur envoie deux requêtes de refresh en même temps ?"*
> **Votre réponse :**  
> *"Dans `auth.service.ts`, dès que la première requête arrive, on passe immédiatement le jeton à `revoked = true` en base avant d'émettre les nouveaux tokens. Si une deuxième requête arrive avec le même ancien jeton, le test `storedToken.revoked` échoue et la deuxième requête reçoit une erreur 401 Unauthorized. Cela protège l'application contre le rejeu de jetons volés."*

### ❓ Question 2 : *"Pourquoi ne stockes-tu pas directement le Refresh Token en clair dans MongoDB ?"*
> **Votre réponse :**  
> *"Parce qu'un Refresh Token confère le droit d'ouvrir une session. Si notre base de données venait à fuiter, un pirate pourrait usurper l'identité de tous nos utilisateurs. En stockant uniquement son empreinte SHA-256 (`tokenHash`), même avec un accès complet à la base, les jetons restent inutilisables."*

### ❓ Question 3 : *"Comment empêches-tu un étudiant de créer un compte avec le rôle 'admin' ?"*
> **Votre réponse :**  
> *"La route publique `POST /auth/register` n'écoute même pas le champ rôle envoyé par le client : dans `auth.service.ts`, le rôle est forcé en dur à `'etudiant'`. Pour créer un compte administrateur ou personnel, il faut obligatoirement passer par la route `POST /admin/users`, qui est protégée par le middleware `authorize('admin')`."*

### ❓ Question 4 : *"Si un administrateur suspend un étudiant, combien de temps l'étudiant peut-il encore utiliser l'application ?"*
> **Votre réponse :**  
> *"Zéro seconde pour obtenir de nouveaux jetons : dès que le statut passe à `suspendu`, `updateUserStatus` révoque tous ses refresh tokens en base. De plus, notre middleware `authenticate` interroge la collection User à chaque requête et vérifie `user.status === 'suspendu'`, ce qui coupe immédiatement tout accès dès le prochain appel API."*
