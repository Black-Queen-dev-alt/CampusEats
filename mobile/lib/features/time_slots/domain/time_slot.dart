import 'package:equatable/equatable.dart';

class TimeSlot extends Equatable {
  const TimeSlot({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.capacity,
    required this.reservedCount,
  });

  final String id;
  final String date;
  final String startTime;
  final String endTime;
  final int capacity;
  final int reservedCount;

  bool get isFull => reservedCount >= capacity;
  int get remaining => (capacity - reservedCount).clamp(0, capacity);

  @override
  List<Object?> get props => [
    id,
    date,
    startTime,
    endTime,
    capacity,
    reservedCount,
  ];
}
