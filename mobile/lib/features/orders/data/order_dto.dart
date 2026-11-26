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
    this.canCancel,
  });

  factory OrderDto.fromJson(Map<String, dynamic> json) {
    int readInt(dynamic value, [int fallback = 0]) =>
        value is int ? value : int.tryParse('$value') ?? fallback;
    final rawItems = json['items'] ?? json['lines'];
    if (rawItems is! List || rawItems.any((item) => item is! Map)) {
      throw const FormatException('Les lignes de commande sont invalides');
    }
    final items = <OrderItem>[];
    for (final raw in rawItems) {
      final map = Map<String, dynamic>.from(raw as Map);
      final rawDish = map['dishId'] ?? map['dish'];
      final dish = rawDish is Map
          ? Map<String, dynamic>.from(rawDish)
          : const <String, dynamic>{};
      final dishId = rawDish is Map ? rawDish['_id'] ?? rawDish['id'] : rawDish;
      items.add(
        OrderItem(
          dishId: dishId == null || '$dishId'.isEmpty ? null : '$dishId',
          name: '${map['dishName'] ?? map['name'] ?? dish['name'] ?? 'Plat'}',
          quantity: readInt(map['quantity'] ?? 1),
          unitPrice: readInt(
            map['unitPriceInCents'] ??
                map['unitPrice'] ??
                map['price'] ??
                map['snapshotPrice'] ??
                dish['priceInCents'],
          ),
        ),
      );
    }
    final rawSlot = json['timeSlot'] ?? json['slotId'] ?? json['slot'];
    final slot = rawSlot is Map
        ? Map<String, dynamic>.from(rawSlot)
        : const <String, dynamic>{};
    final slotId = rawSlot is Map
        ? '${slot['_id'] ?? slot['id'] ?? ''}'
        : '${rawSlot ?? json['timeSlotId'] ?? ''}';
    String slotLabel = '${json['timeSlotLabel'] ?? ''}';
    if (slot.isNotEmpty) {
      slotLabel =
          '${slot['startTime'] ?? ''}${slot['endTime'] == null ? '' : ' - ${slot['endTime']}'}';
    }
    final computedTotal = items.fold<int>(
      0,
      (sum, item) => sum + item.subtotal,
    );
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
      total: readInt(json['total'] ?? json['totalInCents'], computedTotal),
      status: status,
      cancellationDeadline: deadline,
      qrValue: json['qrCode'] is String
          ? json['qrCode'] as String
          : json['qr'] is String
          ? json['qr'] as String
          : null,
      canCancel: json['canCancel'] is bool
          ? json['canCancel'] as bool
          : json['cancellationAllowed'] is bool
          ? json['cancellationAllowed'] as bool
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
  final bool? canCancel;

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
    canCancel: canCancel,
  );
}
