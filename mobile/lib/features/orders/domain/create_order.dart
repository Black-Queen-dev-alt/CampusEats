import 'package:campus_eats_mobile/features/orders/domain/order.dart';
import 'package:campus_eats_mobile/features/orders/domain/orders_repository.dart';

class CreateOrder {
  const CreateOrder(this.repository);
  final OrdersRepository repository;

  Future<OrderResult> call({
    required String menuId,
    required String timeSlotId,
    required List<OrderItem> items,
  }) => repository.createOrder(
    menuId: menuId,
    timeSlotId: timeSlotId,
    items: items,
  );
}
