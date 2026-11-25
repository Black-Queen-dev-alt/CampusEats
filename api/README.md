# CampusEats API

## Description
API REST Node.js/Express 5 avec MongoDB pour l'application CampusEats. Ce projet implémente les modules **orders** et **devices** ainsi que les notifications push Firebase (FCM).

## Prérequis
- **Node.js** (v20 ou supérieur) et **npm** installés.
- Une base MongoDB (le projet utilise `mongodb-memory-server` pour les tests ; pour le développement, configurez `MONGODB_URI` dans `.env`).
- **Clé de service Firebase** (fichier JSON) pour les notifications push.

## Installation
```powershell
cd C:\Users\Congo\OneDrive\Desktop\CampusEats\CampusEats\api
npm install
```

## Configuration Firebase
1. Dans la console Firebase, créez un compte de service et téléchargez le fichier JSON.
2. Copiez‑le dans le répertoire `api/` sous le nom **`firebase-service-key.json`**.
3. Le fichier est déjà listé dans `.gitignore` afin qu’il ne soit pas versionné.

## Scripts utiles
- **Démarrer le serveur en mode développement**
  ```powershell
  npm run dev   # ou `pnpm dev` si vous utilisez pnpm
  ```
- **Exécuter les tests**
  ```powershell
  npm test
  ```
- **Lancer les tests en mode « watch »**
  ```powershell
  npm run test:watch
  ```

## Endpoints principaux
| Méthode | URL | Description |
|--------|-----|-------------|
| `POST` | `/orders` | Crée une nouvelle commande |
| `GET`  | `/orders` | Liste toutes les commandes |
| `POST` | `/orders/:id/cancel` | Annule une commande et libère la place |
| `GET`  | `/time‑slots/:id/orders` | Récupère les commandes d’un créneau horaire |
| `PATCH`| `/orders/:id/status` | Met à jour le statut (received → preparing → ready → withdrawn) |
| `POST` | `/devices` | Enregistre un appareil pour les notifications |

## Workflow des commandes
1. **received** – la commande vient d’être créée.
2. **preparing** – le repas est en cours de préparation.
3. **ready** – le repas est prêt ; une notification push est envoyée via Firebase.
4. **withdrawn** – le repas a été retiré par l’utilisateur.

## Gestion des vulnérabilités
Après l’installation, vous pouvez auditer les dépendances :
```powershell
npm audit   # afficher les vulnérabilités
npm audit fix --force   # appliquer les correctifs (attention aux ruptures possibles)
```

---
*Ce README sera versionné dans la branche `feat/api-orders`.*