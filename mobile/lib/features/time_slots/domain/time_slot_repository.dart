import 'package:campus_eats_mobile/core/errors/failure.dart';
import 'package:campus_eats_mobile/features/time_slots/domain/time_slot.dart';

typedef TimeSlotsResult = ({List<TimeSlot> value, Failure? failure});

abstract class TimeSlotRepository {
  Future<TimeSlotsResult> getTimeSlots(String date);
}
