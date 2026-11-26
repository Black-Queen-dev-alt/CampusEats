import 'package:dio/dio.dart';
import 'package:campus_eats_mobile/core/errors/error_mapper.dart';
import 'package:campus_eats_mobile/core/errors/failure.dart';
import 'package:campus_eats_mobile/features/time_slots/data/time_slot_remote_data_source.dart';
import 'package:campus_eats_mobile/features/time_slots/domain/time_slot.dart';
import 'package:campus_eats_mobile/features/time_slots/domain/time_slot_repository.dart';

class TimeSlotRepositoryImpl implements TimeSlotRepository {
  const TimeSlotRepositoryImpl(this.remote);

  final TimeSlotRemoteDataSource remote;

  @override
  Future<TimeSlotsResult> getTimeSlots(String date) async {
    try {
      final dtos = await remote.getTimeSlots(date);
      return (value: dtos.map((dto) => dto.toDomain()).toList(), failure: null);
    } on DioException catch (error) {
      return (value: <TimeSlot>[], failure: mapDioError(error));
    } on FormatException {
      return (
        value: <TimeSlot>[],
        failure: const ServerFailure('Réponse API invalide'),
      );
    }
  }
}
