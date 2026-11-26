import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:campus_eats_mobile/core/theme/app_spacing.dart';
import 'package:campus_eats_mobile/core/widgets/app_button.dart';
import 'package:campus_eats_mobile/core/widgets/app_text_field.dart';
import 'package:campus_eats_mobile/features/auth/domain/auth_validators.dart';
import 'package:campus_eats_mobile/features/auth/presentation/bloc/auth_bloc.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String? _nameError;
  String? _emailError;
  String? _pwdError;
  String? _confirmError;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final nameError = AuthValidators.fullName(_nameCtrl.text);
    final emailError = AuthValidators.email(_emailCtrl.text);
    final pwdError = AuthValidators.password(_pwdCtrl.text);
    final confirmError = AuthValidators.confirmPassword(
      _pwdCtrl.text,
      _confirmCtrl.text,
    );
    setState(() {
      _nameError = nameError;
      _emailError = emailError;
      _pwdError = pwdError;
      _confirmError = confirmError;
    });
    if (nameError != null ||
        emailError != null ||
        pwdError != null ||
        confirmError != null) {
      return;
    }

    context.read<AuthBloc>().add(
      RegisterRequested(
        fullName: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _pwdCtrl.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Retour',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/welcome'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Créer mon compte', style: theme.textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Commandez à l\'avance, évitez la file d\'attente.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.l),
              AppTextField(
                labelText: 'Nom complet',
                hintText: 'Camille Dupont',
                controller: _nameCtrl,
                errorText: _nameError,
                prefixIcon: Icons.person_outline,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
              ),
              const SizedBox(height: AppSpacing.m),
              AppTextField(
                labelText: 'Email universitaire',
                hintText: 'prenom.nom@univ-campus.fr',
                controller: _emailCtrl,
                errorText: _emailError,
                prefixIcon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
              ),
              const SizedBox(height: AppSpacing.m),
              AppTextField(
                labelText: 'Mot de passe',
                hintText: '8 caractères minimum',
                controller: _pwdCtrl,
                errorText: _pwdError,
                prefixIcon: Icons.lock_outline,
                obscureText: true,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
              ),
              const SizedBox(height: AppSpacing.m),
              AppTextField(
                labelText: 'Confirmer le mot de passe',
                controller: _confirmCtrl,
                errorText: _confirmError,
                prefixIcon: Icons.lock_outline,
                obscureText: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.l),
              BlocConsumer<AuthBloc, AuthState>(
                listener: (context, state) {
                  if (state is! AuthFailure) return;
                  setState(() {
                    _nameError = state.fieldErrors['fullName'];
                    _emailError = state.fieldErrors['email'];
                    _pwdError = state.fieldErrors['password'];
                  });
                  if (state.fieldErrors.isEmpty) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(state.message)));
                  }
                },
                builder: (context, state) => AppButton(
                  label: 'Créer mon compte',
                  isLoading: state is AuthLoading,
                  onPressed: _submit,
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Déjà inscrit ? Se connecter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
