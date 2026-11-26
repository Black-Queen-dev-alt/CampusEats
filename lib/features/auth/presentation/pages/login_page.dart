import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:campus_eats/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:campus_eats/core/widgets/app_text_field.dart';
import 'package:campus_eats/core/widgets/app_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  String? _emailError;
  String? _pwdError;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connexion')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            AppTextField(
              labelText: 'Email',
              controller: _emailCtrl,
              errorText: _emailError,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            AppTextField(
              labelText: 'Mot de passe',
              controller: _pwdCtrl,
              errorText: _pwdError,
              obscureText: true,
            ),
            const SizedBox(height: 24),
            BlocListener<AuthBloc, AuthState>(
              listener: (context, state) {
                if (state is AuthFailure) {
                  // Suppose que le message d’erreur 422 vient déjà formaté.
                  setState(() {
                    _emailError = state.fieldErrors["email"];
                    _pwdError = state.fieldErrors["password"];
                  });
                } else if (state is Authenticated) {
                  context.go('/home');
                }
              },
              child: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  final loading = state is AuthLoading;
                  return AppButton(
                    label: loading ? 'Connexion...' : 'Se connecter',
                    enabled: !loading,
                    onPressed: () {
                      context.read<AuthBloc>().add(LoginRequested(
                        email: _emailCtrl.text.trim(),
                        password: _pwdCtrl.text,
                      ));
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
