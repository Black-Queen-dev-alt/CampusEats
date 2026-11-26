import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:campus_eats_mobile/features/menu/data/menu_dto.dart';

class MenuLocalDataSource {
  const MenuLocalDataSource();

  String _key(String date) => 'campus_eats_menu_$date';

  Future<({MenuDto? menu, DateTime? cachedAt})> getMenu(String date) async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString(_key(date));
    if (value == null) return (menu: null, cachedAt: null);
    final decoded = jsonDecode(value);
    if (decoded is! Map) {
      throw const FormatException('Le cache du menu est invalide');
    }
    final json = Map<String, dynamic>.from(decoded);
    final timestamp = DateTime.tryParse('${json['cachedAt'] ?? ''}');
    if (timestamp == null || json['menu'] is! Map) {
      throw const FormatException('Le cache du menu est incomplet');
    }
    return (
      menu: MenuDto.fromCache(Map<String, dynamic>.from(json['menu'] as Map)),
      cachedAt: timestamp,
    );
  }

  Future<bool> saveMenu(String date, MenuDto menu) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.setString(
      _key(date),
      jsonEncode({
        'cachedAt': DateTime.now().toIso8601String(),
        'menu': menu.toCacheJson(),
      }),
    );
  }

  Future<void> removeMenu(String date) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_key(date));
  }
}
