# 📋 DOSSIER DE RÉPARTITION DE L'API – PROJET CAMPUSEATS
**Version :** 1.0 | **Stack :** Node.js 24 + Express 5 + MongoDB (Mongoose) + TypeScript  
**Objectif :** Développer l'API complète à 4 en parallèle, sans conflit Git et en respectant 100 % des exigences académiques.

---

## 🎯 1. RÈGLES DU JEU COMMUNES (À LIRE PAR TOUS)

Avant d'écrire la moindre ligne de code, l'équipe s'accorde sur ces 5 règles fondamentales :

1. **Format unique des réponses d'erreur (Exigence A5) :**  
   Toutes les erreurs doivent renvoyer cette structure JSON :
   ```json
   {
     "success": false,
     "error": {
       "code": "SLOT_FULL",
       "message": "Ce créneau horaire est complet.",
       "details": null
     }
   }
   ```
2. **Validation stricte (Exigence A4) :**  
   Chaque endpoint valide ses entrées (`body`, `query`, `params`) avec un schéma **Zod**. Les champs inconnus sont automatiquement supprimés (`strip`).
3. **Codes HTTP stricts :**  
   - `200` : Succès avec données
   - `201` : Ressource créée
   - `204` : Succès sans contenu (ex: logout)
   - `400` : Requête malformée
   - `401` : Non authentifié (token manquant ou invalide)
   - `403` : Accès refusé (rôle insuffisant ou tentative de toucher aux données d'un autre)
   - `404` : Ressource non trouvée
   - `409` : Conflit métier (ex: créneau complet, statut déjà avancé, email déjà pris)
   - `422` : Erreur de validation Zod
4. **Montants financiers stockés en entiers (RG09) :**  
   Pour éviter les imprécisions des nombres à virgule, les prix sont stockés en centimes entiers (ex: `330` pour 3.30 €).
5. **Workflow Git :**  
   - Branche principale protégée : `main`
   - Chaque membre travaille sur sa branche (`feat/api-nom-fonctionnalite`)
   - Chaque Pull Request (PR) doit être relue et validée par au moins un autre membre.

---

## 👥 2. FICHES DE POSTE INDIVIDUELLES

---

### 👤 DÉVELOPPEUR 1 : Sécurité, Authentification & Gestion des Utilisateurs

* **Branche Git :** `feat/api-auth-users`
* **Dossiers attribués :** 
  - `src/modules/auth/`
  - `src/modules/users/`
  - `src/common/middlewares/auth.middleware.ts`
  - `src/common/middlewares/role.middleware.ts`
  - `test/auth.test.ts`

#### Responsabilités & Règles de Gestion :
- **RG01 & RG02 :** Tout utilisateur possède un compte et un rôle (`etudiant`, `personnel`, `admin`).
- **RG10 :** Un utilisateur ne peut jamais modifier son propre rôle.
- **RG13 :** Un compte avec le statut `suspendu` ne peut plus se connecter ni commander.
- **A6 (Sécurité) :** Mots de passe hachés avec **Argon2id** (ou bcrypt). Émission d'un Access Token JWT de courte durée (15 min) et d'un Refresh Token rotatif stocké haché en BDD. La déconnexion révoque la session.

#### Endpoints sous sa responsabilité :
| Méthode | Route | Accès | Description | Code Succès |
| :--- | :--- | :--- | :--- | :--- |
| `POST` | `/auth/register` | Public | Inscription publique (crée uniquement le rôle `etudiant`) | `201` |
| `POST` | `/auth/login` | Public | Connexion avec email/mdp -> retourne `{ accessToken, refreshToken }` | `200` |
| `POST` | `/auth/refresh` | Public (Token) | Rotation du Refresh Token -> nouveau Access + nouveau Refresh | `200` |
| `POST` | `/auth/logout` | Connecté | Révocation du Refresh Token actif en base de données | `204` |
| `GET` | `/me` | Connecté | Profil de l'utilisateur connecté | `200` |
| `PATCH` | `/me` | Connecté | Modification du profil (nom, téléphone - rôle interdit) | `200` |
| `POST` | `/admin/users` | Admin | Création d'un compte `personnel` ou `admin` | `201` |
| `PATCH` | `/admin/users/:id/status` | Admin | Suspension ou réactivation d'un compte | `200` |

---

### 👤 DÉVELOPPEUR 2 : Catalogue des Plats, Menus du Jour & Données de Démo

* **Branche Git :** `feat/api-menus-dishes`
* **Dossiers attribués :** 
  - `src/modules/dishes/`
  - `src/modules/menus/`
  - `src/database/seed.ts`
  - `test/menus.test.ts`

#### Responsabilités & Règles de Gestion :
- **RG11 :** Seul l'administrateur peut créer/modifier les plats et publier les menus journaliers.
- **Modèle Dish :** `name`, `description`, `price` (entier), `photoUrl`, `allergens` (array), `isActive`.
- **Modèle Menu :** `date` (index unique `YYYY-MM-DD`), `dishes` (lignes intégrées référençant `dishId` avec champ `isAvailable`), `isPublished`.
- **Données de démo (`src/database/seed.ts`) :** Écrire le script `npm run seed` qui réinitialise la base et insère des comptes de test pour chaque rôle (Admin, Personnel, Étudiant) et les menus de la semaine.

#### Endpoints sous sa responsabilité :
| Méthode | Route | Accès | Description | Code Succès |
| :--- | :--- | :--- | :--- | :--- |
| `GET` | `/menus?date=YYYY-MM-DD` | Connecté | Consulter le menu du jour sélectionné | `200` |
| `GET` | `/dishes` | Connecté | Liste paginée de tous les plats (filtre par nom ou allergène) | `200` |
| `POST` | `/dishes` | Admin | Créer un nouveau plat dans le catalogue | `201` |
| `PATCH` | `/dishes/:id` | Admin | Modifier un plat (prix, statut actif/inactif) | `200` |
| `POST` | `/menus` | Admin | Créer et composer le menu d'une date donnée | `201` |
| `PATCH` | `/menus/:id` | Admin | Mettre à jour la composition ou publier le menu | `200` |

---

### 👤 DÉVELOPPEUR 3 : Créneaux de Retrait & Moteur de Concurrence Atomique

* **Branche Git :** `feat/api-time-slots`
* **Dossiers attribués :** 
  - `src/modules/time-slots/`
  - `test/concurrency.test.ts`

#### Responsabilités & Règles de Gestion :
- **RG03 (Règle critique) :** La capacité d'un créneau ne peut **JAMAIS** être dépassée, même sous 50 requêtes simultanées.
- **RG08 :** Interdiction de réserver un créneau passé ou déjà commencé.
- **Modèle TimeSlot :** `date` (`YYYY-MM-DD`), `startTime` (`11:45`), `endTime` (`12:00`), `capacity` (nombre max de commandes), `reservedCount` (défaut 0).
- **Index MongoDB :** Index composé unique sur `{ date: 1, startTime: 1 }`.
- **Services atomiques à fournir aux autres développeurs :**
  ```typescript
  // Réservation atomique (appelée par Dev 4 lors d'une commande)
  async function reserveSlotAtomically(slotId: string): Promise<TimeSlot> {
    const slot = await TimeSlot.findOneAndUpdate(
      { _id: slotId, $expr: { $lt: ['$reservedCount', '$capacity'] } },
      { $inc: { reservedCount: 1 } },
      { new: true }
    );
    if (!slot) throw AppError.conflict('Créneau complet', 'SLOT_FULL');
    return slot;
  }

  // Libération atomique (appelée par Dev 4 lors d'une annulation)
  async function releaseSlotAtomically(slotId: string): Promise<void> {
    await TimeSlot.findByIdAndUpdate(slotId, { $inc: { reservedCount: -1 } });
  }
  ```

#### Endpoints sous sa responsabilité :
| Méthode | Route | Accès | Description | Code Succès |
| :--- | :--- | :--- | :--- | :--- |
| `GET` | `/time-slots?date=YYYY-MM-DD` | Connecté | Lister les créneaux d'un jour avec places restantes (`capacity - reservedCount`) | `200` |
| `POST` | `/time-slots` | Admin | Créer des créneaux de retrait avec leur capacité max | `201` |
| `PATCH` | `/time-slots/:id` | Admin | Modifier la capacité ou les horaires d'un créneau | `200` |

---

### 👤 DÉVELOPPEUR 4 : Commandes, Workflow d'États & Notifications Push

* **Branche Git :** `feat/api-orders`
* **Dossiers attribués :** 
  - `src/modules/orders/`
  - `src/modules/devices/`
  - `requests.http` (ou collection Postman/Bruno)
  - `test/orders.test.ts`

#### Responsabilités & Règles de Gestion :
- **RG04 :** Un étudiant ne peut voir et annuler que ses propres commandes.
- **RG05 & RG06 :** Seul le personnel change le statut d'une commande. Workflow strict :  
  `recue` ➔ `en_preparation` ➔ `prete` ➔ `retiree`. **Aucun saut d'étape ni retour en arrière possible.**
- **RG07 :** Une commande peut être annulée par l'étudiant uniquement si son statut est encore `recue` et avant l'échéance (ex: 30 min avant le début du créneau). L'annulation appelle la libération atomique du Dev 3.
- **RG09 :** Le prix de chaque ligne est **figé/copié** au moment de la commande. Le montant total est calculé par le serveur.
- **Fonctionnalité avancée (Notifications Push FCM) :**
  - Endpoint `POST /devices` pour enregistrer le token Firebase Cloud Messaging de l'utilisateur.
  - Dès qu'une commande passe au statut `prete`, envoyer la notification push à l'étudiant.

#### Endpoints sous sa responsabilité :
| Méthode | Route | Accès | Description | Code Succès |
| :--- | :--- | :--- | :--- | :--- |
| `POST` | `/orders` | Étudiant | Passer commande (vérifie le menu, réserve le créneau atomiquement) | `201` |
| `GET` | `/orders` | Étudiant | Liste paginée de **ses propres** commandes | `200` |
| `GET` | `/orders/:id` | Étudiant (proprio) ou Personnel | Détail complet d'une commande | `200` |
| `POST` | `/orders/:id/cancel` | Étudiant (proprio) | Annuler la commande et libérer la place du créneau | `200` |
| `GET` | `/time-slots/:id/orders?status=` | Personnel | Voir toutes les commandes à préparer pour un créneau | `200` |
| `PATCH` | `/orders/:id/status` | Personnel | Avancer le statut selon le workflow strict | `200` |
| `POST` | `/devices` | Connecté | Enregistrer le token de notification de son téléphone | `201` |

---

## 📅 3. CALENDRIER D'ASSEMBLAGE (CHRONOGRAMME)

```text
JOUR 1 : Kickoff d'équipe
         - Création du repo Git et du squelette commun (config, env, error handler, database).
         - Création des 4 branches de travail.

JOUR 2 : Développement parallèle des modules de base
         - Dev 1 : Auth & User Model
         - Dev 2 : Dishes, Menus Model & Seed
         - Dev 3 : TimeSlot Model & Algorithme atomique
         - Dev 4 : Schéma Order & Enregistrement FCM Devices

JOUR 3 : Intégration et premier Merge
         - Fusion des PRs de Dev 1, Dev 2 et Dev 3 sur 'main'.
         - Exécution du script 'npm run seed'. Tout le monde a la même base locale.

JOUR 4 : Cœur métier (Orders) & Interconnexion
         - Dev 4 utilise les modules Auth, Menus et TimeSlots pour finaliser les commandes et le workflow.
         - Dev 3 écrit le test de concurrence sous charge.

JOUR 5 : Tests globaux, Déploiement & Documentation
         - Lancement de toute la suite de tests : `npm run test`.
         - Déploiement de l'API en HTTPS sur Render / Railway + MongoDB Atlas.
         - Export de la collection Postman / requests.http (Dev 4).
```
