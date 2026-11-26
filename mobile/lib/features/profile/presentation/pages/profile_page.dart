import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:campus_eats_mobile/app/di/injection.dart';
import 'package:campus_eats_mobile/core/theme/app_colors.dart';
import 'package:campus_eats_mobile/core/theme/app_spacing.dart';
import 'package:campus_eats_mobile/core/widgets/app_button.dart';
import 'package:campus_eats_mobile/core/widgets/app_text_field.dart';
import 'package:campus_eats_mobile/features/auth/data/auth_repository.dart';
import 'package:campus_eats_mobile/features/auth/domain/user.dart';
import 'package:campus_eats_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:campus_eats_mobile/features/auth/presentation/cubit/profile_cubit.dart';

String roleLabel(UserRole role) => switch (role) {
  UserRole.etudiant => 'Étudiant',
  UserRole.personnel => 'Personnel',
  UserRole.admin => 'Administrateur',
};

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    if (authState is! Authenticated) return const SizedBox.shrink();

    return BlocProvider(
      create: (_) => ProfileCubit(
        repository: getIt<AuthRepository>(),
        authBloc: context.read<AuthBloc>(),
      ),
      child: _ProfileView(user: authState.user),
    );
  }
}

class _ProfileView extends StatefulWidget {
  const _ProfileView({required this.user});

  final User user;

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView> {
  late final TextEditingController _nameCtrl = TextEditingController(
    text: widget.user.fullName,
  );

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text('Vous devrez vous reconnecter pour commander.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.read<AuthBloc>().add(const LogoutRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = widget.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    _initials(user.fullName),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              Text(
                user.fullName,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                user.email,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.s),
              Center(
                child: Chip(
                  label: Text(roleLabel(user.role)),
                  backgroundColor: AppColors.primaryLight,
                  side: BorderSide.none,
                ),
              ),
              const SizedBox(height: AppSpacing.l),
              BlocConsumer<ProfileCubit, ProfileState>(
                listener: (context, state) {
                  if (state.status == ProfileStatus.saved ||
                      (state.status == ProfileStatus.failure &&
                          state.fieldErrors.isEmpty)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.message ?? '')),
                    );
                  }
                },
                builder: (context, state) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      labelText: 'Nom complet',
                      controller: _nameCtrl,
                      errorText: state.fieldErrors['fullName'],
                      prefixIcon: Icons.person_outline,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.name],
                    ),
                    const SizedBox(height: AppSpacing.m),
                    AppButton(
                      label: 'Enregistrer',
                      isLoading: state.status == ProfileStatus.saving,
                      onPressed: () =>
                          context.read<ProfileCubit>().saveName(_nameCtrl.text),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Se déconnecter',
                icon: Icons.logout,
                variant: AppButtonVariant.outlined,
                onPressed: _confirmLogout,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
