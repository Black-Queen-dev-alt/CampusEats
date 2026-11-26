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
import 'package:campus_eats_mobile/features/time_slots/data/time_slot_remote_data_source.dart';
import 'package:campus_eats_mobile/features/time_slots/data/time_slot_repository_impl.dart';
import 'package:campus_eats_mobile/features/time_slots/domain/get_time_slots.dart';
import 'package:campus_eats_mobile/features/time_slots/domain/time_slot_repository.dart';
import 'package:campus_eats_mobile/features/time_slots/presentation/bloc/time_slots_bloc.dart';
import 'package:campus_eats_mobile/features/orders/data/orders_remote_data_source.dart';
import 'package:campus_eats_mobile/features/orders/data/orders_repository_impl.dart';
import 'package:campus_eats_mobile/features/orders/domain/cancel_order.dart';
import 'package:campus_eats_mobile/features/orders/domain/create_order.dart';
import 'package:campus_eats_mobile/features/orders/domain/get_order.dart';
import 'package:campus_eats_mobile/features/orders/domain/get_orders.dart';
import 'package:campus_eats_mobile/features/orders/domain/orders_repository.dart';
import 'package:campus_eats_mobile/features/orders/presentation/bloc/orders_bloc.dart';
import 'package:campus_eats_mobile/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:campus_eats_mobile/features/menu/data/menu_local_data_source.dart';
import 'package:campus_eats_mobile/features/menu/data/menu_remote_data_source.dart';
import 'package:campus_eats_mobile/features/menu/data/menu_repository_impl.dart';
import 'package:campus_eats_mobile/features/menu/domain/get_menu.dart';
import 'package:campus_eats_mobile/features/menu/domain/menu_repository.dart';
import 'package:campus_eats_mobile/features/menu/presentation/bloc/menu_bloc.dart';

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

  // Créneaux et commandes : implémentations réelles de l'API CampusEats.
  getIt.registerLazySingleton<TimeSlotRepository>(
    () => TimeSlotRepositoryImpl(TimeSlotRemoteDataSource(getIt<ApiClient>())),
  );
  getIt.registerLazySingleton<GetTimeSlots>(
    () => GetTimeSlots(getIt<TimeSlotRepository>()),
  );
  getIt.registerFactory<TimeSlotsBloc>(
    () => TimeSlotsBloc(getTimeSlots: getIt<GetTimeSlots>()),
  );

  getIt.registerLazySingleton<OrdersRepository>(
    () => OrdersRepositoryImpl(OrdersRemoteDataSource(getIt<ApiClient>())),
  );
  getIt.registerLazySingleton<GetOrders>(
    () => GetOrders(getIt<OrdersRepository>()),
  );
  getIt.registerLazySingleton<GetOrder>(
    () => GetOrder(getIt<OrdersRepository>()),
  );
  getIt.registerLazySingleton<CreateOrder>(
    () => CreateOrder(getIt<OrdersRepository>()),
  );
  getIt.registerLazySingleton<CancelOrder>(
    () => CancelOrder(getIt<OrdersRepository>()),
  );
  getIt.registerLazySingleton<OrdersBloc>(
    () => OrdersBloc(
      getOrders: getIt<GetOrders>(),
      getOrder: getIt<GetOrder>(),
      createOrder: getIt<CreateOrder>(),
      cancelOrder: getIt<CancelOrder>(),
    ),
  );

  getIt.registerLazySingleton<MenuLocalDataSource>(
    () => const MenuLocalDataSource(),
  );
  getIt.registerLazySingleton<MenuRemoteDataSource>(
    () => MenuRemoteDataSource(getIt<ApiClient>()),
  );
  getIt.registerLazySingleton<MenuRepository>(
    () => MenuRepositoryImpl(
      remote: getIt<MenuRemoteDataSource>(),
      local: getIt<MenuLocalDataSource>(),
    ),
  );
  getIt.registerLazySingleton<GetMenu>(() => GetMenu(getIt<MenuRepository>()));
  getIt.registerFactory<MenuBloc>(() => MenuBloc(getMenu: getIt<GetMenu>()));
  getIt.registerLazySingleton<CartCubit>(CartCubit.new);
}
