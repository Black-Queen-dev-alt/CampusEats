import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:campus_eats/core/theme/app_spacing.dart';

class AppTextField extends StatelessWidget {
  final String labelText;
  final TextEditingController controller;
  final String? errorText; // texte d'erreur 422
  final bool obscureText;
  final TextInputType keyboardType;

  const AppTextField({
    Key? key,
    required this.labelText,
    required this.controller,
    this.errorText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(labelText),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            errorText: errorText,
          ),
        ),
      ],
    );
  }
}
