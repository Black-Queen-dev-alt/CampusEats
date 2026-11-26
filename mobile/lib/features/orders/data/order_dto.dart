import 'package:campus_eats_mobile/features/orders/domain/order.dart';

class OrderDto {
  const OrderDto({
    required this.id,
    required this.number,
    required this.timeSlotId,
    required this.timeSlotLabel,
    required this.items,
    required this.total,
    required this.status,
    this.cancellationDeadline,
    this.qrValue,
  });

  factory OrderDto.fromJson(Map<String, dynamic> json) {
    int readInt(dynamic value) =>
        value is int ? value : int.tryParse('$value') ?? 0;
    final rawItems = json['items'];
    final items = <OrderItem>[];
    if (rawItems is List) {
      for (final raw in rawItems) {
        if (raw is Map) {
          final map = Map<String, dynamic>.from(raw);
          items.add(
            OrderItem(
              name: '${map['name'] ?? map['dishName'] ?? 'Plat'}',
              quantity: readInt(map['quantity'] ?? 1),
              unitPrice: readInt(
                map['unitPrice'] ?? map['price'] ?? map['snapshotPrice'],
              ),
            ),
          );
        }
      }
    }
    final slot = json['timeSlot'];
    String slotId = '${json['timeSlotId'] ?? ''}';
    String slotLabel = '${json['timeSlotLabel'] ?? ''}';
    if (slot is Map) {
      slotId = '${slot['_id'] ?? slot['id'] ?? slotId}';
      slotLabel =
          '${slot['startTime'] ?? ''}${slot['endTime'] == null ? '' : ' - ${slot['endTime']}'}';
    }
    DateTime? deadline;
    if (json['cancellationDeadline'] != null) {
      deadline = DateTime.tryParse('${json['cancellationDeadline']}');
    }
    final status = '${json['status'] ?? json['state'] ?? ''}';
    return OrderDto(
      id: '${json['_id'] ?? json['id'] ?? ''}',
      number: '${json['number'] ?? json['_id'] ?? json['id'] ?? ''}',
      timeSlotId: slotId,
      timeSlotLabel: slotLabel.isEmpty ? 'Créneau de retrait' : slotLabel,
      items: items,
      total: readInt(json['total']),
      status: status,
      cancellationDeadline: deadline,
      qrValue: json['qrCode'] is String
          ? json['qrCode'] as String
          : json['qr'] is String
          ? json['qr'] as String
          : null,
    );
  }

  final String id;
  final String number;
  final String timeSlotId;
  final String timeSlotLabel;
  final List<OrderItem> items;
  final int total;
  final String status;
  final DateTime? cancellationDeadline;
  final String? qrValue;

  Order toDomain() => Order(
    id: id,
    number: number,
    timeSlotId: timeSlotId,
    timeSlotLabel: timeSlotLabel,
    items: items,
    total: total,
    status: OrderStatus.fromApi(status),
    cancellationDeadline: cancellationDeadline,
    qrValue: qrValue,
  );
}
