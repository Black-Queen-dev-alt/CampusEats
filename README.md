# CampusEats 🥪

> Application mobile full-stack de précommande au restaurant universitaire avec créneaux de retrait limités pour fluidifier les files d'attente à midi.

Projet académique développé dans le cadre du cours *Développement Mobile Avancé - Année 3* (Sujet T1).

## 👥 Équipe & Rôles
- **Membre 1 (Team Lead) :** Sécurité, Authentification & Utilisateurs (`src/modules/auth`, `src/modules/users`)
- **Membre 2 (API Lead) :** Catalogue Plats, Menus du Jour & Données de démo (`src/modules/dishes`, `src/modules/menus`, `seed.ts`)
- **Membre 3 (App Lead) :** Créneaux de Retrait & Moteur de Concurrence Atomique (`src/modules/time-slots`)
- **Membre 4 (Quality & UX Lead) :** Commandes, Workflow d'états, Vue Personnel & Notifications (`src/modules/orders`, `src/modules/devices`)

## 📖 Dossier de Répartition de l'API
Consultez le dossier complet de répartition pour l'équipe dans :
👉 [docs/REPARTITION_API_EQUIPE.md](docs/REPARTITION_API_EQUIPE.md)

## 🛠️ Démarrage Local Rapide (API)

```bash
cd api
cp .env.example .env
npm install
npm run seed       # Remplir la base de données avec les données de test
npm run dev        # Démarrer le serveur en mode dev avec rechargement à chaud
```

Les comptes de démonstration sont créés par `npm run seed` :

| Rôle | Email | Mot de passe |
|---|---|---|
| Administrateur | `admin@campuseats.univ.edu` | `Admin1234!` |
| Personnel | `staff@campuseats.univ.edu` | `Staff1234!` |
| Étudiant | `student@campuseats.univ.edu` | `Student1234!` |
| Étudiant secondaire | `student2@campuseats.univ.edu` | `Student1234!` |

### Endpoints API principaux

| Méthode | Chemin | Rôle |
|---|---|---|
| POST | `/auth/register` | Public |
| POST | `/auth/login` | Public |
| POST | `/auth/refresh` | Public |
| POST | `/auth/logout` | Public |
| GET/PATCH | `/me` | Authentifié |
| POST | `/admin/users` | Admin |
| PATCH | `/admin/users/:id/status` | Admin |
| GET/POST | `/dishes` | Authentifié / Admin |
| GET/PATCH | `/dishes/:id` | Authentifié / Admin |
| GET/POST | `/menus` | Authentifié / Admin |
| PATCH | `/menus/:id` | Admin |
| GET/POST | `/time-slots` | Authentifié / Admin |
| PATCH | `/time-slots/:id` | Admin |
| POST/GET | `/orders` | Étudiant |
| POST | `/orders/:id/cancel` | Étudiant |
| GET | `/time-slots/:id/orders` | Personnel / Admin |
| PATCH | `/orders/:id/status` | Personnel / Admin |
| POST | `/devices` | Utilisateur authentifié |
| GET | `/health` | Public |

Les exemples détaillés des requêtes sont dans [api/requests.http](api/requests.http). Le seed crée les comptes de démonstration de façon idempotente et ne supprime pas les données existantes.
