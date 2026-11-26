import 'package:campus_eats_mobile/features/orders/domain/orders_repository.dart';

class GetOrder {
  const GetOrder(this.repository);
  final OrdersRepository repository;

  Future<OrderResult> call(String id) => repository.getOrder(id);
}
