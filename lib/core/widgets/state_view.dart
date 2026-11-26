import 'package:flutter/material.dart';
import 'package:campus_eats/core/theme/app_spacing.dart';

/// Widget générique affichant les différents états d’une donnée.
///
/// * **loading** – spinner centré.
/// * **empty** – texte "Aucun résultat".
/// * **error** – texte d’erreur + bouton "Réessayer".
/// * **content** – le widget fourni via le paramètre `child`.
class StateView extends StatelessWidget {
  final bool isLoading;
  final bool isEmpty;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final Widget? child;

  const StateView({
    Key? key,
    this.isLoading = false,
    this.isEmpty = false,
    this.errorMessage,
    this.onRetry,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: AppSpacing.s),
            if (onRetry != null)
              ElevatedButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      );
    }
    if (isEmpty) {
      return const Center(child: Text('Aucun résultat'));
    }
    return child ?? const SizedBox.shrink();
  }
}
