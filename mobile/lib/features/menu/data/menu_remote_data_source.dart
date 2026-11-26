import 'package:campus_eats_mobile/core/network/api_client.dart';
import 'package:campus_eats_mobile/features/menu/data/menu_dto.dart';

class MenuRemoteDataSource {
  const MenuRemoteDataSource(this.apiClient);

  final ApiClient apiClient;

  Future<MenuDto> getMenu(String date) async {
    final response = await apiClient.get<dynamic>(
      '/menus',
      queryParameters: {'date': date},
    );
    final body = response.data;
    if (body is! Map) {
      throw const FormatException('Réponse API menu invalide');
    }
    final data = body['data'];
    if (data is! Map) {
      throw const FormatException('Menu absent de la réponse API');
    }
    return MenuDto.fromJson(Map<String, dynamic>.from(data));
  }
}
