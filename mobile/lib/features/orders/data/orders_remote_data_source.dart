import 'package:campus_eats_mobile/core/network/api_client.dart';
import 'package:campus_eats_mobile/features/orders/data/order_dto.dart';

class OrdersRemoteDataSource {
  const OrdersRemoteDataSource(this.apiClient);
  final ApiClient apiClient;

  Map<String, dynamic> _readResource(dynamic body) {
    if (body is! Map) {
      throw const FormatException('Réponse API commande invalide');
    }
    final data = body['data'] ?? body['order'] ?? body;
    if (data is! Map) {
      throw const FormatException('Réponse API commande invalide');
    }
    return Map<String, dynamic>.from(data);
  }

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
    if (list is! List) {
      throw const FormatException('Réponse API historique invalide');
    }
    if (list.any((item) => item is! Map)) {
      throw const FormatException('Une commande de l’historique est invalide');
    }
    final items = list
        .cast<Map>()
        .map((item) => OrderDto.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    bool hasMore = false;
    var hasPaginationMetadata = false;
    if (body is Map) {
      final topLevelPagination = body['pagination'];
      final meta = body['meta'];
      final pagination = body['pagination'];
      if (topLevelPagination is Map) {
        final pageValue = topLevelPagination['page'];
        final totalPages = topLevelPagination['totalPages'];
        if (pageValue is int && totalPages is int) {
          hasMore = pageValue < totalPages;
          hasPaginationMetadata = true;
        }
      }
      if (pagination is Map) {
        final pageValue = pagination['page'];
        final totalPages = pagination['totalPages'];
        if (pageValue is int && totalPages is int) {
          hasMore = pageValue < totalPages;
          hasPaginationMetadata = true;
        }
      }
      if (meta is Map) {
        final next = meta['next'] ?? meta['hasMore'];
        if (next is bool) {
          hasMore = next;
          hasPaginationMetadata = true;
        }
        if (next is int) {
          hasMore = page < next;
          hasPaginationMetadata = true;
        }
      }
      if (!hasPaginationMetadata) hasMore = items.length == limit;
    } else {
      hasMore = items.length == limit;
    }
    return (items: items, hasMore: hasMore);
  }

  Future<OrderDto> getOrder(String id) async {
    final response = await apiClient.get<dynamic>('/orders/$id');
    return OrderDto.fromJson(_readResource(response.data));
  }

  Future<OrderDto> createOrder({
    required String menuId,
    required String timeSlotId,
    required List<Map<String, dynamic>> items,
  }) async {
    final response = await apiClient.post<dynamic>(
      '/orders',
      data: {'menuId': menuId, 'slotId': timeSlotId, 'lines': items},
    );
    return OrderDto.fromJson(_readResource(response.data));
  }

  Future<OrderDto> cancelOrder(String id) async {
    final response = await apiClient.post<dynamic>('/orders/$id/cancel');
    return OrderDto.fromJson(_readResource(response.data));
  }
}
