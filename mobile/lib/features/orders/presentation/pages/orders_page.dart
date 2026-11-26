import 'package:flutter/material.dart';
import 'package:campus_eats_mobile/core/widgets/coming_soon_page.dart';

/// Écran « Mes commandes » : à remplacer par la personne 3.
class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonPage(
      title: 'Mes commandes',
      detail: 'Historique et suivi des commandes (lot personne 3).',
    );
  }
}

/// Détail d'une commande, cible du lien direct des notifications push.
/// À remplacer par la personne 3.
class OrderDetailPage extends StatelessWidget {
  const OrderDetailPage({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    return ComingSoonPage(
      title: 'Commande',
      detail: 'Détail de la commande $orderId (lot personne 3).',
    );
  }
}
