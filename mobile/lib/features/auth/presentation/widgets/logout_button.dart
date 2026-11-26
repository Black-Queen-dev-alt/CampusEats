import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:campus_eats_mobile/features/auth/presentation/bloc/auth_bloc.dart';

/// Bouton de déconnexion pour les AppBar (temporaire, avant l'écran Profil).
class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Se déconnecter',
      icon: const Icon(Icons.logout),
      onPressed: () => context.read<AuthBloc>().add(const LogoutRequested()),
    );
  }
}
