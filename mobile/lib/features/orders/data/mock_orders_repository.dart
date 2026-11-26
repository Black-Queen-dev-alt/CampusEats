import 'package:campus_eats_mobile/core/errors/failure.dart';
import 'package:campus_eats_mobile/features/orders/domain/order.dart';
import 'package:campus_eats_mobile/features/orders/domain/orders_repository.dart';

/// Jeu de données temporaire pour tester les écrans pendant que les contrats
/// /orders restent à confirmer. Aucun endpoint réel n'est simulé comme réussi.
class MockOrdersRepository implements OrdersRepository {
  MockOrdersRepository() {
    _orders = [
      Order(
        id: 'order-1001',
        number: 'CE-1001',
        timeSlotId: 'slot-1130',
        timeSlotLabel: '11:30 - 12:00',
        items: const [
          OrderItem(name: 'Riz sauce arachide', quantity: 1, unitPrice: 2500),
          OrderItem(name: 'Salade fraiche', quantity: 1, unitPrice: 1200),
        ],
        total: 3700,
        status: OrderStatus.received,
        cancellationDeadline: DateTime.now().add(const Duration(hours: 2)),
      ),
      Order(
        id: 'order-1002',
        number: 'CE-1002',
        timeSlotId: 'slot-1230',
        timeSlotLabel: '12:30 - 13:00',
        items: const [
          OrderItem(name: 'Poulet yassa', quantity: 1, unitPrice: 3000),
        ],
        total: 3000,
        status: OrderStatus.ready,
      ),
    ];
  }

  late List<Order> _orders;

  @override
  Future<OrdersPageResult> getOrders({
    required int page,
    required int limit,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final start = (page - 1) * limit;
    if (start >= _orders.length) {
      return (value: <Order>[], hasMore: false, failure: null);
    }
    final end = (start + limit).clamp(0, _orders.length);
    return (
      value: _orders.sublist(start, end),
      hasMore: end < _orders.length,
      failure: null,
    );
  }

  @override
  Future<OrderResult> getOrder(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    for (final order in _orders) {
      if (order.id == id) return (value: order, failure: null);
    }
    return (
      value: null,
      failure: const NotFoundFailure('Commande introuvable'),
    );
  }

  @override
  Future<OrderResult> createOrder({
    required String timeSlotId,
    required List<OrderItem> items,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (timeSlotId == 'slot-1200') {
      return (
        value: null,
        failure: const ConflictFailure(
          'Ce créneau vient d\'être complété. Choisissez-en un autre.',
        ),
      );
    }
    final total = items.fold<int>(0, (sum, item) => sum + item.subtotal);
    final order = Order(
      id: 'order-${1000 + _orders.length + 1}',
      number: 'CE-${1000 + _orders.length + 1}',
      timeSlotId: timeSlotId,
      timeSlotLabel: 'Créneau sélectionné',
      items: items,
      total: total,
      status: OrderStatus.received,
      cancellationDeadline: DateTime.now().add(const Duration(hours: 2)),
    );
    _orders.insert(0, order);
    return (value: order, failure: null);
  }

  @override
  Future<OrderResult> cancelOrder(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final index = _orders.indexWhere((order) => order.id == id);
    if (index == -1) {
      return (
        value: null,
        failure: const NotFoundFailure('Commande introuvable'),
      );
    }
    final previous = _orders[index];
    if (!previous.status.cancellable) {
      return (
        value: null,
        failure: const ConflictFailure(
          'Le délai d\'annulation est dépassé ou le statut a changé.',
        ),
      );
    }
    final cancelled = previous.copyWith(status: OrderStatus.cancelled);
    _orders[index] = cancelled;
    return (value: cancelled, failure: null);
  }
}
