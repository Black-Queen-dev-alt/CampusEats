import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:campus_eats_mobile/core/errors/failure.dart';
import 'package:campus_eats_mobile/core/storage/secure_token_storage.dart';
import 'package:campus_eats_mobile/features/auth/data/auth_repository.dart';
import 'package:campus_eats_mobile/features/auth/domain/user.dart';
import 'package:campus_eats_mobile/features/auth/presentation/bloc/auth_bloc.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockTokenStorage extends Mock implements SecureTokenStorage {}

void main() {
  late MockAuthRepository repository;
  late MockTokenStorage storage;

  const user = User(
    id: '1',
    email: 'camille@univ.fr',
    fullName: 'Camille Dupont',
    role: UserRole.etudiant,
  );
  const session = AuthSession(
    user: user,
    accessToken: 'access',
    refreshToken: 'refresh',
  );

  setUp(() {
    repository = MockAuthRepository();
    storage = MockTokenStorage();
    when(() => storage.saveAccessToken(any())).thenAnswer((_) async {});
    when(() => storage.saveRefreshToken(any())).thenAnswer((_) async {});
    when(() => storage.clearAll()).thenAnswer((_) async {});
  });

  AuthBloc build() => AuthBloc(repository: repository, tokenStorage: storage);

  group('AppStarted', () {
    blocTest<AuthBloc, AuthState>(
      'sans token : non connecté',
      setUp: () {
        when(() => storage.readAccessToken()).thenAnswer((_) async => null);
        when(() => storage.readRefreshToken()).thenAnswer((_) async => null);
      },
      build: build,
      act: (bloc) => bloc.add(const AppStarted()),
      expect: () => [const Unauthenticated()],
    );

    blocTest<AuthBloc, AuthState>(
      'avec session valide : connecté',
      setUp: () {
        when(() => storage.readAccessToken()).thenAnswer((_) async => 'a');
        when(() => storage.readRefreshToken()).thenAnswer((_) async => 'r');
        when(() => repository.me()).thenAnswer((_) async => user);
      },
      build: build,
      act: (bloc) => bloc.add(const AppStarted()),
      expect: () => [const Authenticated(user)],
    );

    blocTest<AuthBloc, AuthState>(
      'session refusée par le serveur : tokens effacés',
      setUp: () {
        when(() => storage.readAccessToken()).thenAnswer((_) async => 'a');
        when(() => storage.readRefreshToken()).thenAnswer((_) async => 'r');
        when(() => repository.me())
            .thenAnswer((_) async => throw const UnauthorizedFailure());
      },
      build: build,
      act: (bloc) => bloc.add(const AppStarted()),
      expect: () => [const Unauthenticated()],
      verify: (_) => verify(() => storage.clearAll()).called(1),
    );
  });

  group('LoginRequested', () {
    blocTest<AuthBloc, AuthState>(
      'succès : tokens sauvegardés et utilisateur connecté',
      setUp: () {
        when(
          () => repository.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => session);
      },
      build: build,
      act: (bloc) => bloc.add(
        const LoginRequested(email: 'camille@univ.fr', password: 'secret123'),
      ),
      expect: () => [const AuthLoading(), const Authenticated(user)],
      verify: (_) {
        verify(() => storage.saveAccessToken('access')).called(1);
        verify(() => storage.saveRefreshToken('refresh')).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'erreur 422 : messages par champ',
      setUp: () {
        when(
          () => repository.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer(
          (_) async => throw const ValidationFailure(
            'Données invalides',
            fieldErrors: {'email': 'Email invalide'},
          ),
        );
      },
      build: build,
      act: (bloc) => bloc.add(const LoginRequested(email: 'x', password: 'y')),
      expect: () => [
        const AuthLoading(),
        const AuthFailure(
          message: 'Données invalides',
          fieldErrors: {'email': 'Email invalide'},
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'identifiants refusés (401) : message du serveur',
      setUp: () {
        when(
          () => repository.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer(
          (_) async => throw const UnauthorizedFailure(
            'Email ou mot de passe incorrect.',
          ),
        );
      },
      build: build,
      act: (bloc) =>
          bloc.add(const LoginRequested(email: 'a@b.fr', password: 'mauvais')),
      expect: () => [
        const AuthLoading(),
        const AuthFailure(message: 'Email ou mot de passe incorrect.'),
      ],
    );
  });

  group('RegisterRequested', () {
    blocTest<AuthBloc, AuthState>(
      'succès : connecté',
      setUp: () {
        when(
          () => repository.register(
            fullName: any(named: 'fullName'),
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => session);
      },
      build: build,
      act: (bloc) => bloc.add(
        const RegisterRequested(
          fullName: 'Camille Dupont',
          email: 'camille@univ.fr',
          password: 'secret123',
        ),
      ),
      expect: () => [const AuthLoading(), const Authenticated(user)],
    );
  });

  group('LogoutRequested', () {
    blocTest<AuthBloc, AuthState>(
      'efface la session même si le serveur est injoignable',
      setUp: () {
        when(() => storage.readRefreshToken()).thenAnswer((_) async => 'r');
        when(() => repository.logout(any()))
            .thenAnswer((_) async => throw const NetworkFailure());
      },
      build: build,
      act: (bloc) => bloc.add(const LogoutRequested()),
      expect: () => [const Unauthenticated()],
      verify: (_) => verify(() => storage.clearAll()).called(1),
    );
  });

  group('UserUpdated', () {
    blocTest<AuthBloc, AuthState>(
      'met à jour le nom de l\'utilisateur connecté',
      setUp: () {
        when(() => storage.readAccessToken()).thenAnswer((_) async => 'a');
        when(() => storage.readRefreshToken()).thenAnswer((_) async => 'r');
        when(() => repository.me()).thenAnswer((_) async => user);
      },
      build: build,
      act: (bloc) async {
        bloc.add(const AppStarted());
        await Future<void>.delayed(const Duration(milliseconds: 50));
        bloc.add(
          const UserUpdated(
            User(
              id: '1',
              email: 'camille@univ.fr',
              fullName: 'Camille D.',
              role: UserRole.etudiant,
            ),
          ),
        );
      },
      expect: () => [
        const Authenticated(user),
        const Authenticated(
          User(
            id: '1',
            email: 'camille@univ.fr',
            fullName: 'Camille D.',
            role: UserRole.etudiant,
          ),
        ),
      ],
    );
  });
}
