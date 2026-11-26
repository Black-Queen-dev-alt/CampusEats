import 'package:campus_eats_mobile/features/orders/domain/order.dart';

abstract class OrdersEvent {
  const OrdersEvent();
}

class OrdersRequested extends OrdersEvent {
  const OrdersRequested();
}

class LoadNextOrdersPage extends OrdersEvent {
  const LoadNextOrdersPage();
}

class OrderDetailsRequested extends OrdersEvent {
  const OrderDetailsRequested(this.id);
  final String id;
}

class CreateOrderRequested extends OrdersEvent {
  const CreateOrderRequested({required this.timeSlotId, required this.items});
  final String timeSlotId;
  final List<OrderItem> items;
}

class CancelOrderRequested extends OrdersEvent {
  const CancelOrderRequested(this.id);
  final String id;
}
