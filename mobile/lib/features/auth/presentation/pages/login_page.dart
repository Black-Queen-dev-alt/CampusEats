import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:campus_eats_mobile/core/theme/app_spacing.dart';
import 'package:campus_eats_mobile/core/widgets/app_button.dart';
import 'package:campus_eats_mobile/core/widgets/app_logo.dart';
import 'package:campus_eats_mobile/core/widgets/app_text_field.dart';
import 'package:campus_eats_mobile/features/auth/domain/auth_validators.dart';
import 'package:campus_eats_mobile/features/auth/presentation/bloc/auth_bloc.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  String? _emailError;
  String? _pwdError;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final emailError = AuthValidators.email(_emailCtrl.text);
    final pwdError = AuthValidators.requiredField(
      _pwdCtrl.text,
      'Le mot de passe est requis',
    );
    setState(() {
      _emailError = emailError;
      _pwdError = pwdError;
    });
    if (emailError != null || pwdError != null) return;

    context.read<AuthBloc>().add(
      LoginRequested(email: _emailCtrl.text.trim(), password: _pwdCtrl.text),
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
              const Center(child: AppLogo(size: 96)),
              const SizedBox(height: AppSpacing.l),
              Text('Bon retour !', style: theme.textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Connectez-vous pour commander votre repas.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.l),
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
                controller: _pwdCtrl,
                errorText: _pwdError,
                prefixIcon: Icons.lock_outline,
                obscureText: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.l),
              // La navigation après connexion est faite par le router (redirect).
              BlocConsumer<AuthBloc, AuthState>(
                listener: (context, state) {
                  if (state is! AuthFailure) return;
                  setState(() {
                    _emailError = state.fieldErrors['email'];
                    _pwdError = state.fieldErrors['password'];
                  });
                  if (state.fieldErrors.isEmpty) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(state.message)));
                  }
                },
                builder: (context, state) => AppButton(
                  label: 'Se connecter',
                  isLoading: state is AuthLoading,
                  onPressed: _submit,
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              TextButton(
                onPressed: () => context.go('/register'),
                child: const Text('Pas encore de compte ? Créer un compte'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
