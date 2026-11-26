import 'package:campus_eats_mobile/core/network/api_client.dart';
import 'package:campus_eats_mobile/features/orders/data/order_dto.dart';

class OrdersRemoteDataSource {
  const OrdersRemoteDataSource(this.apiClient);
  final ApiClient apiClient;

  Future<({List<OrderDto> items, bool hasMore})> getOrders({
    required int page,
    required int limit,
  }) async {
    final response = await apiClient.get<dynamic>(
      '/orders',
      queryParameters: {'page': page, 'limit': limit},
    );
    final body = response.data;
    final list = body is Map
        ? (body['data'] ?? body['orders'] ?? body['items'])
        : body;
    final items = list is List
        ? list
              .whereType<Map>()
              .map((item) => OrderDto.fromJson(Map<String, dynamic>.from(item)))
              .toList()
        : <OrderDto>[];
    bool hasMore = false;
    if (body is Map) {
      final meta = body['meta'];
      if (meta is Map) {
        final next = meta['next'] ?? meta['hasMore'];
        if (next is bool) hasMore = next;
        if (next is int) hasMore = page < next;
      }
      hasMore = hasMore || items.length == limit;
    } else {
      hasMore = items.length == limit;
    }
    return (items: items, hasMore: hasMore);
  }

  Future<OrderDto> getOrder(String id) async {
    final response = await apiClient.get<dynamic>('/orders/$id');
    final body = response.data;
    final data = body is Map ? (body['data'] ?? body['order'] ?? body) : body;
    return OrderDto.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<OrderDto> createOrder({
    required String timeSlotId,
    required List<Map<String, dynamic>> items,
  }) async {
    final response = await apiClient.post<dynamic>(
      '/orders',
      data: {'timeSlotId': timeSlotId, 'items': items},
    );
    final body = response.data;
    final data = body is Map ? (body['data'] ?? body['order'] ?? body) : body;
    return OrderDto.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<OrderDto> cancelOrder(String id) async {
    final response = await apiClient.post<dynamic>('/orders/$id/cancel');
    final body = response.data;
    final data = body is Map ? (body['data'] ?? body['order'] ?? body) : body;
    return OrderDto.fromJson(Map<String, dynamic>.from(data as Map));
  }
}
