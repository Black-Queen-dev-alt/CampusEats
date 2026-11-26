import 'package:flutter/material.dart';
import 'package:campus_eats_mobile/core/widgets/state_view.dart';

/// Page temporaire d'un écran qui appartient à un autre lot.
/// Le responsable du lot la remplace par son vrai écran.
class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({super.key, required this.title, this.detail});

  final String title;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: StateMessage(
        icon: Icons.construction_rounded,
        title: 'Bientôt disponible',
        message: detail ?? 'Cet écran est en cours de développement.',
      ),
    );
  }
}
