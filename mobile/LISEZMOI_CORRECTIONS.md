# CampusEats mobile : lot 1 (socle, authentification, navigation, notifications)

## 1. Appliquer
1. Copier ce dossier `mobile/` PAR-DESSUS ton dossier `mobile/` (accepter le remplacement),
   et `.github/workflows/ci.yml` à la racine du dépôt.
2. SUPPRIMER ces fichiers (remplacés) :
   - mobile/lib/app/router/route_guards.dart
   - mobile/lib/app/router/home_shell.dart
3. Dans `mobile/` :
   flutter clean
   flutter pub get
   dart format .          <- OBLIGATOIRE avant de pousser : le CI vérifie le formatage
   flutter analyze
   flutter test

## 2. Lancer avec l'API
API : `cd api && npm run dev` (port 3000).
- Émulateur Android :        flutter run
- Téléphone réel (même Wi-Fi) : flutter run --dart-define=API_BASE_URL=http://IP_DU_PC:3000
- Chrome / Windows :          flutter run --dart-define=API_BASE_URL=http://localhost:3000
Après un changement de main.dart : arrêter et relancer (R majuscule), pas seulement le hot reload.

Comptes de test : crée un étudiant avec "Créer un compte". Le personnel et l'admin
viennent du seed de l'API (api/src/database/seed.ts).

## 3. Contenu du lot 1
- Design system : couleurs du logo, thème Material 3 unique, boutons 52 dp, champs avec icônes.
- Widgets communs : AppButton, AppTextField (mot de passe masquable), StateView (4 états :
  squelette / vide / erreur + Réessayer / hors ligne), SkeletonList, StatusBadge.order,
  OfflineBanner, AppLogo, BrandHeader, ComingSoonPage.
- Écrans : Splash, Bienvenue, Connexion, Inscription, Profil (modifier son nom, déconnexion).
- Navigation : redirect unique par rôle ; barre du bas étudiant (Accueil / Mes Commandes /
  Profil) et admin (Dashboard / Menus / Commandes / Paramètres) ; route /orders/:id.
- Session : tokens chiffrés, GET /me au démarrage, refresh unique même avec plusieurs 401.
- Notifications FCM : permission après connexion, POST /devices, lien direct vers /orders/:id.
- Logo : assets/images/logo.png + icônes Android (mipmap).
- Tests : AuthBloc, redirections de routes, refresh concurrent (3 x 401 = 1 refresh), StateView.

## 4. À savoir
### Notifications (Firebase)
Sans configuration Firebase le service se désactive tout seul (l'app marche normalement).
Pour les activer :
1. Créer un projet Firebase, ajouter l'app Android (package com.example.mobile ou le tien).
2. Mettre google-services.json dans mobile/android/app/.
3. Ajouter dans mobile/android/settings.gradle.kts le plugin
   `id("com.google.gms.google-services") version "4.4.2" apply false`
   et dans mobile/android/app/build.gradle.kts `id("com.google.gms.google-services")`.
   (Ou lancer `flutterfire configure`.)
### Côté API (petite modification)
Le lien direct vers la commande a besoin de l'identifiant. Dans
api/src/modules/orders/order.service.ts, ajouter à l'envoi de la notification « prête » :
   data: { orderId: String(updatedOrder.id) }
### Statuts de commande
L'API renvoie : received, preparing, ready, withdrawn, cancelled.
`StatusBadge.order(status)` les affiche en français.
