# Démonstration — créneaux et commandes (7 minutes)

## Préparation

- Deux téléphones connectés au même environnement API et à Internet.
- Téléphone A : compte étudiant de démonstration ayant un panier vide.
- Téléphone B : deuxième compte étudiant de démonstration.
- Un compte personnel est prêt pour vérifier le changement de statut.
- Un menu publié et un créneau futur sont disponibles. Pour le conflit, garder un créneau de test avec une seule place restante.
- Lancer les deux applications avec la même URL `API_BASE_URL`. Ne pas afficher de jetons, mots de passe ou secrets à l’écran.

## Déroulé chronométré

| Temps | Démonstration |
|---|---|
| 0:00–0:40 | Présenter les deux comptes étudiants et le menu publié. Vérifier la date affichée sur chaque téléphone. |
| 0:40–1:30 | Sur A, ajouter un plat, modifier sa quantité et montrer le total en centimes formaté à l’écran. Ouvrir le choix du créneau et montrer qu’un créneau complet n’est pas sélectionnable. |
| 1:30–2:20 | Sur les deux téléphones, sélectionner le créneau avec une place restante et laisser les écrans de confirmation prêts. |
| 2:20–3:20 | Confirmer sur A et B au même signal. Un seul envoi doit réussir; l’autre doit afficher le conflit, garder le panier et permettre de choisir un autre créneau. Montrer que le détail ne s’ouvre qu’après la réponse positive de l’API. |
| 3:20–4:10 | Ouvrir l’historique de la commande réussie. Sur le téléphone en conflit, choisir un autre créneau et retenter si le temps le permet. Montrer le statut en toutes lettres, le créneau et les prix enregistrés. |
| 4:10–5:00 | Ouvrir le détail d’une commande admissible à l’annulation et vérifier la règle fournie par l’API. Lancer l’annulation et montrer l’état « Annulation en cours », puis la confirmation serveur. |
| 5:00–5:50 | Avec le compte personnel, faire avancer une commande non annulée de « Reçue » à « En préparation », puis à « Prête ». Recharger son détail sur le téléphone étudiant et montrer le nouveau statut. |
| 5:50–6:35 | Vérifier qu’une commande annulée ou arrivée à l’échéance n’offre plus l’action d’annulation. Présenter l’écran d’historique vide ou la pagination si les données de démonstration le permettent. |
| 6:35–7:00 | Résumer les garanties : capacité décidée par le serveur, conflit 409 sans perte du panier, création non confirmée avant réponse API, annulation refusée restaurée sans perte de l’état précédent. |

## Plan B si le réseau tombe

Ne pas présenter une commande comme confirmée hors ligne. Montrer l’erreur réseau et l’action « Réessayer », rétablir la connexion, puis relancer la requête. Si l’API reste inaccessible, expliquer le parcours attendu avec une commande déjà présente dans les données de démonstration; ne pas fabriquer de réponse ni de statut côté client.
