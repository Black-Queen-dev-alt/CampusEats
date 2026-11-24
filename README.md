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
