import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campus_eats_mobile/core/errors/failure.dart';
import 'package:campus_eats_mobile/core/widgets/state_view.dart';
import 'package:campus_eats_mobile/features/auth/domain/auth_validators.dart';
import 'package:campus_eats_mobile/features/auth/presentation/pages/welcome_page.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('WelcomePage affiche les deux actions', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: WelcomePage()));

    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.text('Créer un compte'), findsOneWidget);
    expect(find.text('Bien manger, à votre portée'), findsOneWidget);
  });

  group('StateView : les 4 états', () {
    testWidgets('contenu', (tester) async {
      await tester.pumpWidget(
        _wrap(const StateView(child: Text('Mon contenu'))),
      );
      expect(find.text('Mon contenu'), findsOneWidget);
    });

    testWidgets('vide avec action', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(
          StateView(
            isEmpty: true,
            emptyTitle: 'Aucun plat disponible',
            emptyActionLabel: 'Actualiser',
            onEmptyAction: () => tapped = true,
          ),
        ),
      );
      expect(find.text('Aucun plat disponible'), findsOneWidget);
      await tester.tap(find.text('Actualiser'));
      expect(tapped, isTrue);
    });

    testWidgets('erreur avec Réessayer', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        _wrap(
          StateView(
            failure: const ServerFailure(),
            onRetry: () => retried = true,
          ),
        ),
      );
      expect(find.text('Une erreur est survenue'), findsOneWidget);
      await tester.tap(find.text('Réessayer'));
      expect(retried, isTrue);
    });

    testWidgets('erreur réseau : écran hors ligne', (tester) async {
      await tester.pumpWidget(
        _wrap(StateView(failure: const NetworkFailure(), onRetry: () {})),
      );
      expect(find.text('Vous êtes hors ligne'), findsOneWidget);
      expect(find.text('Réessayer'), findsOneWidget);
    });
  });

  group('AuthValidators', () {
    test('email invalide', () {
      expect(AuthValidators.email('abc'), isNotNull);
      expect(AuthValidators.email('camille@univ-paris.fr'), isNull);
    });

    test('mot de passe trop court', () {
      expect(AuthValidators.password('1234567'), isNotNull);
      expect(AuthValidators.password('12345678'), isNull);
    });

    test('confirmation différente', () {
      expect(AuthValidators.confirmPassword('a', 'b'), isNotNull);
      expect(AuthValidators.confirmPassword('a', 'a'), isNull);
    });
  });
}
