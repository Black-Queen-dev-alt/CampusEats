import 'package:campus_eats_mobile/features/orders/domain/orders_repository.dart';

class CancelOrder {
  const CancelOrder(this.repository);
  final OrdersRepository repository;

  Future<OrderResult> call(String id) => repository.cancelOrder(id);
}
