import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:campus_eats_mobile/features/time_slots/domain/get_time_slots.dart';

import 'time_slots_event.dart';
import 'time_slots_state.dart';

class TimeSlotsBloc extends Bloc<TimeSlotsEvent, TimeSlotsState> {
  TimeSlotsBloc({required GetTimeSlots getTimeSlots})
    : _getTimeSlots = getTimeSlots,
      super(const TimeSlotsLoading()) {
    on<TimeSlotsRequested>(_onLoad);
    on<SlotRefreshRequested>(_onLoad);
  }

  final GetTimeSlots _getTimeSlots;

  Future<void> _onLoad(
    TimeSlotsEvent event,
    Emitter<TimeSlotsState> emit,
  ) async {
    final date = event is TimeSlotsRequested
        ? event.date
        : (event as SlotRefreshRequested).date;
    emit(const TimeSlotsLoading());
    final result = await _getTimeSlots(date);
    if (result.failure != null) {
      emit(TimeSlotsFailure(result.failure!));
    } else if (result.value.isEmpty) {
      emit(const TimeSlotsEmpty());
    } else {
      emit(TimeSlotsLoaded(result.value));
    }
  }
}
