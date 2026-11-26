import 'package:campus_eats_mobile/features/time_slots/domain/time_slot.dart';

class TimeSlotDto {
  const TimeSlotDto({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.capacity,
    required this.reservedCount,
    this.remainingPlaces,
  });

  factory TimeSlotDto.fromJson(Map<String, dynamic> json) {
    int readInt(dynamic value, [int fallback = 0]) =>
        value is int ? value : int.tryParse('$value') ?? fallback;
    final capacity = readInt(json['capacity']);
    final remainingPlaces = json['remainingPlaces'] == null
        ? null
        : readInt(json['remainingPlaces'], 0);
    final reservedCount = remainingPlaces != null
        ? (capacity - remainingPlaces).clamp(0, capacity)
        : readInt(json['reservedCount'] ?? json['reserved_count'], 0);
    return TimeSlotDto(
      id: '${json['_id'] ?? json['id'] ?? ''}',
      date: '${json['date'] ?? ''}',
      startTime: '${json['startTime'] ?? json['start'] ?? ''}',
      endTime: '${json['endTime'] ?? json['end'] ?? ''}',
      capacity: capacity,
      reservedCount: reservedCount,
      remainingPlaces: remainingPlaces,
    );
  }

  final String id;
  final String date;
  final String startTime;
  final String endTime;
  final int capacity;
  final int reservedCount;
  final int? remainingPlaces;

  TimeSlot toDomain() => TimeSlot(
    id: id,
    date: date,
    startTime: startTime,
    endTime: endTime,
    capacity: capacity,
    reservedCount: reservedCount,
    remainingPlaces: remainingPlaces,
  );
}
