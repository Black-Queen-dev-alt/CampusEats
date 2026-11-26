import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:campus_eats_mobile/core/errors/failure.dart';
import 'package:campus_eats_mobile/core/storage/secure_token_storage.dart';
import 'package:campus_eats_mobile/features/auth/data/auth_repository.dart';
import 'package:campus_eats_mobile/features/auth/domain/user.dart';

// Les directives `part` viennent TOUJOURS après les `import`.
part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required AuthRepository repository,
    required SecureTokenStorage tokenStorage,
  }) : _repository = repository,
       _tokenStorage = tokenStorage,
       super(const AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<SessionExpired>(_onSessionExpired);
    on<UserUpdated>(_onUserUpdated);
  }

  final AuthRepository _repository;
  final SecureTokenStorage _tokenStorage;

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    final access = await _tokenStorage.readAccessToken();
    final refresh = await _tokenStorage.readRefreshToken();
    if (access == null && refresh == null) {
      emit(const Unauthenticated());
      return;
    }
    try {
      final user = await _repository.me();
      emit(Authenticated(user));
    } on Failure catch (failure) {
      if (failure is UnauthorizedFailure) await _tokenStorage.clearAll();
      emit(const Unauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final session = await _repository.login(
        email: event.email,
        password: event.password,
      );
      await _saveSession(session);
      emit(Authenticated(session.user));
    } on Failure catch (failure) {
      emit(_toAuthFailure(failure));
    }
  }

  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final session = await _repository.register(
        fullName: event.fullName,
        email: event.email,
        password: event.password,
      );
      await _saveSession(session);
      emit(Authenticated(session.user));
    } on Failure catch (failure) {
      emit(_toAuthFailure(failure));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    final refresh = await _tokenStorage.readRefreshToken();
    try {
      await _repository.logout(refresh);
    } on Failure {
      // Même si le serveur est injoignable, on déconnecte localement.
    }
    await _tokenStorage.clearAll();
    emit(const Unauthenticated());
  }

  Future<void> _onSessionExpired(
    SessionExpired event,
    Emitter<AuthState> emit,
  ) async {
    await _tokenStorage.clearAll();
    emit(const Unauthenticated());
  }

  void _onUserUpdated(UserUpdated event, Emitter<AuthState> emit) {
    if (state is Authenticated) emit(Authenticated(event.user));
  }

  Future<void> _saveSession(AuthSession session) async {
    await _tokenStorage.saveAccessToken(session.accessToken);
    await _tokenStorage.saveRefreshToken(session.refreshToken);
  }

  AuthFailure _toAuthFailure(Failure failure) {
    return AuthFailure(
      message: failure.message,
      fieldErrors: failure is ValidationFailure
          ? failure.fieldErrors
          : const {},
    );
  }
}
