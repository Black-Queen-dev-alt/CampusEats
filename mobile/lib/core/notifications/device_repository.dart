import 'package:dio/dio.dart';

/// Enregistre le token FCM de l'appareil auprès de l'API (POST /devices).
class DeviceRepository {
  DeviceRepository(this._dio);

  final Dio _dio;

  /// "Au mieux" : un échec n'empêche jamais d'utiliser l'app.
  Future<bool> registerToken(String fcmToken) async {
    try {
      await _dio.post<void>('/devices', data: {'fcmToken': fcmToken});
      return true;
    } on DioException {
      return false;
    }
  }
}
