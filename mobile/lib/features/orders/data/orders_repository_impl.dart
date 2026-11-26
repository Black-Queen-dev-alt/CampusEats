import 'package:dio/dio.dart';
import 'package:campus_eats_mobile/core/errors/error_mapper.dart';
import 'package:campus_eats_mobile/features/orders/data/orders_remote_data_source.dart';
import 'package:campus_eats_mobile/features/orders/domain/order.dart';
import 'package:campus_eats_mobile/features/orders/domain/orders_repository.dart';

class OrdersRepositoryImpl implements OrdersRepository {
  const OrdersRepositoryImpl(this.remote);
  final OrdersRemoteDataSource remote;

  @override
  Future<OrdersPageResult> getOrders({
    required int page,
    required int limit,
  }) async {
    try {
      final result = await remote.getOrders(page: page, limit: limit);
      return (
        value: result.items.map((dto) => dto.toDomain()).toList(),
        hasMore: result.hasMore,
        failure: null,
      );
    } on DioException catch (error) {
      return (value: <Order>[], hasMore: false, failure: mapDioError(error));
    }
  }

  @override
  Future<OrderResult> getOrder(String id) async {
    try {
      final dto = await remote.getOrder(id);
      return (value: dto.toDomain(), failure: null);
    } on DioException catch (error) {
      return (value: null, failure: mapDioError(error));
    }
  }

  @override
  Future<OrderResult> createOrder({
    required String timeSlotId,
    required List<OrderItem> items,
  }) async {
    try {
      final dto = await remote.createOrder(
        timeSlotId: timeSlotId,
        items: items
            .map(
              (item) => {
                'name': item.name,
                'quantity': item.quantity,
                'unitPrice': item.unitPrice,
              },
            )
            .toList(),
      );
      return (value: dto.toDomain(), failure: null);
    } on DioException catch (error) {
      return (value: null, failure: mapDioError(error));
    }
  }

  @override
  Future<OrderResult> cancelOrder(String id) async {
    try {
      final dto = await remote.cancelOrder(id);
      return (value: dto.toDomain(), failure: null);
    } on DioException catch (error) {
      return (value: null, failure: mapDioError(error));
    }
  }
}
