import 'package:campus_eats_mobile/features/orders/domain/orders_repository.dart';

class GetOrders {
  const GetOrders(this.repository);
  final OrdersRepository repository;

  Future<OrdersPageResult> call({required int page, required int limit}) =>
      repository.getOrders(page: page, limit: limit);
}
