import 'package:campus_eats_mobile/features/time_slots/domain/time_slot.dart';

class TimeSlotDto {
  const TimeSlotDto({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.capacity,
    required this.reservedCount,
  });

  factory TimeSlotDto.fromJson(Map<String, dynamic> json) {
    int readInt(dynamic value, [int fallback = 0]) =>
        value is int ? value : int.tryParse('$value') ?? fallback;
    return TimeSlotDto(
      id: '${json['_id'] ?? json['id'] ?? ''}',
      date: '${json['date'] ?? ''}',
      startTime: '${json['startTime'] ?? json['start'] ?? ''}',
      endTime: '${json['endTime'] ?? json['end'] ?? ''}',
      capacity: readInt(json['capacity']),
      reservedCount: readInt(json['reservedCount'] ?? json['reserved_count']),
    );
  }

  final String id;
  final String date;
  final String startTime;
  final String endTime;
  final int capacity;
  final int reservedCount;

  TimeSlot toDomain() => TimeSlot(
    id: id,
    date: date,
    startTime: startTime,
    endTime: endTime,
    capacity: capacity,
    reservedCount: reservedCount,
  );
}
