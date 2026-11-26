import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:campus_eats_mobile/features/time_slots/domain/get_time_slots.dart';
import 'package:campus_eats_mobile/features/time_slots/domain/time_slot.dart';
import 'package:campus_eats_mobile/features/time_slots/domain/time_slot_repository.dart';
import 'package:campus_eats_mobile/features/time_slots/presentation/bloc/time_slots_bloc.dart';
import 'package:campus_eats_mobile/features/time_slots/presentation/bloc/time_slots_event.dart';
import 'package:campus_eats_mobile/features/time_slots/presentation/bloc/time_slots_state.dart';

class _MockTimeSlotRepository extends Mock implements TimeSlotRepository {}

void main() {
  late _MockTimeSlotRepository repository;
  late TimeSlotsBloc bloc;

  setUp(() {
    repository = _MockTimeSlotRepository();
    bloc = TimeSlotsBloc(getTimeSlots: GetTimeSlots(repository));
  });

  tearDown(() => bloc.close());

  blocTest<TimeSlotsBloc, TimeSlotsState>(
    'charge les créneaux',
    build: () {
      when(() => repository.getTimeSlots('2026-11-26')).thenAnswer(
        (_) async => (
          value: const [
            TimeSlot(
              id: '1',
              date: '2026-11-26',
              startTime: '11:30',
              endTime: '12:00',
              capacity: 20,
              reservedCount: 5,
            ),
          ],
          failure: null,
        ),
      );
      return bloc;
    },
    act: (bloc) => bloc.add(const TimeSlotsRequested('2026-11-26')),
    expect: () => [const TimeSlotsLoading(), isA<TimeSlotsLoaded>()],
  );

  blocTest<TimeSlotsBloc, TimeSlotsState>(
    'affiche un état vide',
    build: () {
      when(() => repository.getTimeSlots('2026-11-26'))
          .thenAnswer((_) async => (value: <TimeSlot>[], failure: null));
      return bloc;
    },
    act: (bloc) => bloc.add(const TimeSlotsRequested('2026-11-26')),
    expect: () => [const TimeSlotsLoading(), const TimeSlotsEmpty()],
  );
}
