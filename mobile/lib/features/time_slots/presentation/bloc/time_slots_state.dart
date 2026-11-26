import 'package:equatable/equatable.dart';
import 'package:campus_eats_mobile/core/errors/failure.dart';
import 'package:campus_eats_mobile/features/time_slots/domain/time_slot.dart';

abstract class TimeSlotsState extends Equatable {
  const TimeSlotsState();
  @override
  List<Object?> get props => [];
}

class TimeSlotsLoading extends TimeSlotsState {
  const TimeSlotsLoading();
}

class TimeSlotsLoaded extends TimeSlotsState {
  const TimeSlotsLoaded(this.slots);
  final List<TimeSlot> slots;
  @override
  List<Object?> get props => [slots];
}

class TimeSlotsEmpty extends TimeSlotsState {
  const TimeSlotsEmpty();
}

class TimeSlotsFailure extends TimeSlotsState {
  const TimeSlotsFailure(this.failure);
  final Failure failure;
  @override
  List<Object?> get props => [failure];
}
