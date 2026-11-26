import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:campus_eats/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:campus_eats/core/widgets/app_text_field.dart';
import 'package:campus_eats/core/widgets/app_button.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String? _emailError;
  String? _pwdError;
  String? _confirmError;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inscription')),
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
            const SizedBox(height: 12),
            AppTextField(
              labelText: 'Confirmer le mot de passe',
              controller: _confirmCtrl,
              errorText: _confirmError,
              obscureText: true,
            ),
            const SizedBox(height: 24),
            BlocListener<AuthBloc, AuthState>(
              listener: (context, state) {
                if (state is AuthFailure) {
                  setState(() {
                    _emailError = state.fieldErrors["email"];
                    _pwdError = state.fieldErrors["password"];
                    _confirmError = state.fieldErrors["confirmPassword"];
                  });
                } else if (state is Authenticated) {
                  context.go('/home');
                }
              },
              child: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  final loading = state is AuthLoading;
                  return AppButton(
                    label: loading ? 'Inscription...' : 'S\'inscrire',
                    enabled: !loading,
                    onPressed: () {
                      context.read<AuthBloc>().add(RegisterRequested(
                        email: _emailCtrl.text.trim(),
                        password: _pwdCtrl.text,
                        confirmPassword: _confirmCtrl.text,
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
