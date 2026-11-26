import 'package:campus_eats_mobile/core/network/api_client.dart';
import 'package:campus_eats_mobile/features/time_slots/data/time_slot_dto.dart';

class TimeSlotRemoteDataSource {
  const TimeSlotRemoteDataSource(this.apiClient);

  final ApiClient apiClient;

  Future<List<TimeSlotDto>> getTimeSlots(String date) async {
    final response = await apiClient.get<dynamic>(
      '/time-slots',
      queryParameters: {'date': date},
    );
    final body = response.data;
    final list = body is Map
        ? (body['data'] ?? body['timeSlots'] ?? body['slots'] ?? body['items'])
        : body;
    if (list is! List) {
      throw const FormatException('Réponse API créneaux invalide');
    }
    if (list.any((item) => item is! Map)) {
      throw const FormatException('Un créneau de la réponse API est invalide');
    }
    return list
        .cast<Map>()
        .map((item) => TimeSlotDto.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}
