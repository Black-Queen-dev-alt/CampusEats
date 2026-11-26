import 'package:campus_eats_mobile/core/errors/failure.dart';
import 'package:campus_eats_mobile/features/orders/domain/order.dart';

typedef OrdersPageResult = ({
  List<Order> value,
  bool hasMore,
  Failure? failure,
});
typedef OrderResult = ({Order? value, Failure? failure});

abstract class OrdersRepository {
  Future<OrdersPageResult> getOrders({required int page, required int limit});
  Future<OrderResult> getOrder(String id);
  Future<OrderResult> createOrder({
    required String menuId,
    required String timeSlotId,
    required List<OrderItem> items,
  });
  Future<OrderResult> cancelOrder(String id);
}
