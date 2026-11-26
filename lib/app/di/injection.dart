// Injection de dépendances avec GetIt
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:campus_eats/core/network/api_client.dart';
import 'package:campus_eats/core/network/auth_interceptor.dart';
import 'package:campus_eats/core/storage/secure_token_storage.dart';
import 'package:campus_eats/features/auth/presentation/bloc/auth_bloc.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  // --------------------
  // Dio + API client
  // --------------------
  final dio = Dio(BaseOptions(
    baseUrl: const String.fromEnvironment('API_BASE_URL'),
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  // Auth interceptor ajoute le token aux requêtes
  dio.interceptors.add(AuthInterceptor(const FlutterSecureStorage()));

  // Register singleton instances
  getIt.registerSingleton<Dio>(dio);
  getIt.registerSingleton<ApiClient>(ApiClient(dio));

  // --------------------
  // Secure storage
  // --------------------
  final tokenStorage = SecureTokenStorage();
  getIt.registerSingleton<SecureTokenStorage>(tokenStorage);

  // --------------------
  // Auth Bloc (depends on token storage & API client)
  // --------------------
  getIt.registerFactory<AuthBloc>(() => AuthBloc(
    tokenStorage: tokenStorage,
    apiClient: getIt<ApiClient>(),
  ));

  // TODO: enregistrer les repositories (auth, menus, ...), autres blocs, services.
}
