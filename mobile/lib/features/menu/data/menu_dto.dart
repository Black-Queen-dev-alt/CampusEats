import 'package:campus_eats_mobile/features/menu/data/dish_dto.dart';
import 'package:campus_eats_mobile/features/menu/domain/daily_menu.dart';
import 'package:campus_eats_mobile/features/menu/domain/dish.dart';

class MenuDto {
  const MenuDto({required this.id, required this.date, required this.dishes});

  factory MenuDto.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    if (rawItems is! List) {
      throw const FormatException('La liste des plats du menu est invalide');
    }
    if (rawItems.any((item) => item is! Map)) {
      throw const FormatException('Un élément du menu est invalide');
    }
    final id = '${json['id'] ?? json['_id'] ?? ''}';
    final date = '${json['date'] ?? ''}';
    if (id.isEmpty || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date)) {
      throw const FormatException('Les informations du menu sont invalides');
    }
    return MenuDto(
      id: id,
      date: date,
      dishes: rawItems
          .whereType<Map>()
          .map(
            (item) =>
                DishDto.fromMenuItem(Map<String, dynamic>.from(item))
                    .toDomain(),
          )
          .toList(),
    );
  }

  factory MenuDto.fromCache(Map<String, dynamic> json) {
    final rawDishes = json['dishes'];
    if (rawDishes is! List) {
      throw const FormatException('Le cache du menu est invalide');
    }
    if (rawDishes.any((dish) => dish is! Map)) {
      throw const FormatException('Un élément du cache menu est invalide');
    }
    return MenuDto(
      id: '${json['id'] ?? ''}',
      date: '${json['date'] ?? ''}',
      dishes: rawDishes
          .whereType<Map>()
          .map(
            (dish) =>
                DishDto.fromJson(Map<String, dynamic>.from(dish)).toDomain(),
          )
          .toList(),
    );
  }

  final String id;
  final String date;
  final List<Dish> dishes;

  DailyMenu toDomain() => DailyMenu(id: id, date: date, dishes: dishes);

  Map<String, dynamic> toCacheJson() => {
    'id': id,
    'date': date,
    'dishes': dishes
        .map(
          (dish) => {
            'id': dish.id,
            'name': dish.name,
            'description': dish.description,
            'priceInCents': dish.priceInCents,
            'category': dish.category,
            'photoUrl': dish.photoUrl,
            'allergens': dish.allergens,
            'isVegetarian': dish.isVegetarian,
            'isAvailable': dish.isAvailable,
            'dailyStockLimit': dish.dailyStockLimit,
            'dailyStockUsed': dish.dailyStockUsed,
          },
        )
        .toList(),
  };
}
