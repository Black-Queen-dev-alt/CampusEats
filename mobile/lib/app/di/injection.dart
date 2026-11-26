// Composition root : le seul endroit où l'on assemble les dépendances.
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:campus_eats_mobile/core/network/api_client.dart';
import 'package:campus_eats_mobile/core/notifications/device_repository.dart';
import 'package:campus_eats_mobile/core/notifications/notification_service.dart';
import 'package:campus_eats_mobile/core/network/auth_interceptor.dart';
import 'package:campus_eats_mobile/core/network/refresh_coordinator.dart';
import 'package:campus_eats_mobile/core/storage/secure_token_storage.dart';
import 'package:campus_eats_mobile/features/auth/data/auth_repository.dart';
import 'package:campus_eats_mobile/features/auth/presentation/bloc/auth_bloc.dart';

final getIt = GetIt.instance;

/// URL de l'API, injectée au lancement :
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.20:3000
/// Valeur par défaut : l'émulateur Android voit le PC sur 10.0.2.2.
const String _apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:3000',
);

void setupDependencies() {
  if (getIt.isRegistered<AuthBloc>()) return; // évite un double appel

  final options = BaseOptions(
    baseUrl: _apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  );

  getIt.registerLazySingleton<SecureTokenStorage>(SecureTokenStorage.new);

  // Dio "nu" (sans intercepteur) : sert uniquement à rafraîchir le token.
  final bareDio = Dio(options);
  final refreshCoordinator = RefreshCoordinator(
    dio: bareDio,
    storage: getIt<SecureTokenStorage>(),
    onSessionExpired: () => getIt<AuthBloc>().add(const SessionExpired()),
  );

  // Dio principal, avec token automatique et refresh sur 401.
  final dio = Dio(options);
  dio.interceptors.add(
    AuthInterceptor(
      storage: getIt<SecureTokenStorage>(),
      refreshCoordinator: refreshCoordinator,
      dio: dio,
    ),
  );

  getIt.registerSingleton<Dio>(dio);
  getIt.registerLazySingleton<ApiClient>(() => ApiClient(dio));
  getIt.registerLazySingleton<AuthRepository>(() => AuthRepository(dio));

  getIt.registerLazySingleton<DeviceRepository>(() => DeviceRepository(dio));
  getIt.registerLazySingleton<NotificationService>(
    () => NotificationService(getIt<DeviceRepository>()),
  );

  // lazySingleton (et non factory) : le router et les pages partagent
  // la MÊME instance, donc le même état.
  getIt.registerLazySingleton<AuthBloc>(
    () => AuthBloc(
      repository: getIt<AuthRepository>(),
      tokenStorage: getIt<SecureTokenStorage>(),
    ),
  );
}
