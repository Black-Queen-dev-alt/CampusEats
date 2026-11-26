import 'package:campus_eats_mobile/features/time_slots/domain/time_slot_repository.dart';

class GetTimeSlots {
  const GetTimeSlots(this.repository);

  final TimeSlotRepository repository;

  Future<TimeSlotsResult> call(String date) => repository.getTimeSlots(date);
}
