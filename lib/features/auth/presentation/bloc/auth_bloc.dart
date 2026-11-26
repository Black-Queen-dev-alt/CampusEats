import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:campus_eats/features/auth/domain/user.dart';
import 'package:campus_eats/core/storage/secure_token_storage.dart';
import 'package:campus_eats/core/network/api_client.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SecureTokenStorage tokenStorage;
  final ApiClient apiClient;

  AuthBloc({required this.tokenStorage, required this.apiClient}) : super(const Unauthenticated()) {
    on<AppStarted>(_onAppStarted);
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
    // TODO: add SessionRefreshRequested handling
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    final access = await tokenStorage.readAccessToken();
    if (access != null) {
      // TODO: validate token / fetch user role via /me
      // For now, mock a user
      emit(Authenticated(const User(id: '1', email: 'mock@campus.com', role: 'student')));
    } else {
      emit(const Unauthenticated());
    }
  }

  Future<void> _onLoginRequested(LoginRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      // TODO: appeler l'API /auth/login avec apiClient.dio
      // Simuler succès :
      await Future.delayed(const Duration(seconds: 1));
      // Stocker les tokens (mock)
      await tokenStorage.saveAccessToken('access-token');
      await tokenStorage.saveRefreshToken('refresh-token');
      emit(Authenticated(const User(id: '1', email: event.email, role: 'student')));
    } catch (e) {
      // Simplifié : on renvoie un champ d'erreur générique
      emit(const AuthFailure(fieldErrors: {}));
    }
  }

  Future<void> _onRegisterRequested(RegisterRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      // TODO: appel API /auth/register
      await Future.delayed(const Duration(seconds: 1));
      await tokenStorage.saveAccessToken('access-token');
      await tokenStorage.saveRefreshToken('refresh-token');
      emit(Authenticated(const User(id: '1', email: event.email, role: 'student')));
    } catch (e) {
      emit(const AuthFailure(fieldErrors: {}));
    }
  }

  Future<void> _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) async {
    await tokenStorage.clearAll();
    emit(const Unauthenticated());
  }
}
