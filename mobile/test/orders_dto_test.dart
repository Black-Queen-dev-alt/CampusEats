import 'package:flutter_test/flutter_test.dart';
import 'package:campus_eats_mobile/features/orders/data/order_dto.dart';
import 'package:campus_eats_mobile/features/orders/domain/order.dart';
import 'package:campus_eats_mobile/features/time_slots/data/time_slot_dto.dart';

void main() {
  test('maps the API order snapshot, populated slot and cancellation rule', () {
    final order = OrderDto.fromJson({
      '_id': 'order-1',
      'status': 'preparing',
      'canCancel': true,
      'slotId': {
        '_id': 'slot-1',
        'date': '2026-11-27',
        'startTime': '12:00',
        'endTime': '12:15',
      },
      'lines': [
        {
          'dishId': 'dish-1',
          'dishName': 'Riz',
          'unitPriceInCents': 1250,
          'quantity': 2,
        },
      ],
    }).toDomain();

    expect(order.id, 'order-1');
    expect(order.timeSlotId, 'slot-1');
    expect(order.timeSlotLabel, '12:00 - 12:15');
    expect(order.items.single.dishId, 'dish-1');
    expect(order.items.single.name, 'Riz');
    expect(order.items.single.unitPrice, 1250);
    expect(order.total, 2500);
    expect(order.cancellationAllowed, isTrue);
  });

  test('maps remaining places from the API slot response', () {
    final slot = TimeSlotDto.fromJson({
      '_id': 'slot-1',
      'date': '2026-11-27',
      'startTime': '12:00',
      'endTime': '12:15',
      'capacity': 20,
      'remainingPlaces': 3,
    }).toDomain();

    expect(slot.reservedCount, 17);
    expect(slot.remaining, 3);
    expect(slot.isFull, isFalse);
  });

  test('maps the API withdrawn status to the withdrawn label', () {
    final order = OrderDto.fromJson({
      '_id': 'order-1',
      'status': 'withdrawn',
      'lines': [],
    }).toDomain();

    expect(order.status, OrderStatus.collected);
    expect(order.status.label, 'Retirée');
  });
}
