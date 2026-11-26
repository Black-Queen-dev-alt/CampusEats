import 'package:campus_eats_mobile/features/time_slots/domain/time_slot.dart';
import 'package:campus_eats_mobile/features/time_slots/domain/time_slot_repository.dart';

/// Jeu de données temporaire pour le développement parallèle.
/// Remplacer l'enregistrement GetIt par TimeSlotRepositoryImpl une fois
/// que GET /time-slots aura été validé par l'équipe API.
class MockTimeSlotRepository implements TimeSlotRepository {
  const MockTimeSlotRepository();

  @override
  Future<TimeSlotsResult> getTimeSlots(String date) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return (
      value: [
        TimeSlot(
          id: 'slot-1130',
          date: date,
          startTime: '11:30',
          endTime: '12:00',
          capacity: 20,
          reservedCount: 7,
        ),
        TimeSlot(
          id: 'slot-1200',
          date: date,
          startTime: '12:00',
          endTime: '12:30',
          capacity: 20,
          reservedCount: 20,
        ),
        TimeSlot(
          id: 'slot-1230',
          date: date,
          startTime: '12:30',
          endTime: '13:00',
          capacity: 15,
          reservedCount: 5,
        ),
      ],
      failure: null,
    );
  }
}
