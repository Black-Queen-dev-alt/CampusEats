import 'package:campus_eats_mobile/features/menu/domain/dish.dart';

class DishDto {
  const DishDto({
    required this.id,
    required this.name,
    required this.description,
    required this.priceInCents,
    required this.category,
    required this.allergens,
    required this.isVegetarian,
    required this.isAvailable,
    required this.dailyStockUsed,
    this.photoUrl,
    this.dailyStockLimit,
  });

  factory DishDto.fromMenuItem(Map<String, dynamic> item) {
    final rawDish = item['dishId'] ?? item['dish'];
    if (rawDish is! Map) {
      throw const FormatException('Le plat du menu est invalide');
    }
    final json = Map<String, dynamic>.from(rawDish);
    final price = json['priceInCents'] is int
        ? json['priceInCents'] as int
        : int.tryParse('${json['priceInCents']}');
    final id = '${json['id'] ?? json['_id'] ?? ''}';
    final name = json['name'];
    final description = json['description'];
    final category = json['category'];
    final available = item['isAvailable'];
    if (id.isEmpty ||
        name is! String ||
        description is! String ||
        price == null ||
        price < 0 ||
        category is! String ||
        !const {'entree', 'plat', 'dessert', 'boisson'}.contains(category) ||
        available is! bool) {
      throw const FormatException('Les informations du plat sont invalides');
    }

    int readInt(dynamic value) =>
        value is int ? value : int.tryParse('$value') ?? 0;
    final rawAllergens = json['allergens'];
    final allergens = rawAllergens is List
        ? rawAllergens.whereType<String>().toList()
        : <String>[];
    final rawLimit = item['dailyStockLimit'];
    final limit = rawLimit == null ? null : readInt(rawLimit);
    final used = readInt(item['dailyStockUsed']);
    return DishDto(
      id: id,
      name: name,
      description: description,
      priceInCents: price,
      category: category,
      photoUrl: json['photoUrl'] is String ? json['photoUrl'] as String : null,
      allergens: allergens,
      isVegetarian: json['isVegetarian'] == true,
      isAvailable: available,
      dailyStockLimit: limit,
      dailyStockUsed: used,
    );
  }

  factory DishDto.fromJson(Map<String, dynamic> json) => DishDto(
    id: '${json['id'] ?? ''}',
    name: '${json['name'] ?? ''}',
    description: '${json['description'] ?? ''}',
    priceInCents: json['priceInCents'] is int
        ? json['priceInCents'] as int
        : int.tryParse('${json['priceInCents']}') ?? 0,
    category: '${json['category'] ?? 'plat'}',
    photoUrl: json['photoUrl'] is String ? json['photoUrl'] as String : null,
    allergens: json['allergens'] is List
        ? (json['allergens'] as List).whereType<String>().toList()
        : const [],
    isVegetarian: json['isVegetarian'] == true,
    isAvailable: json['isAvailable'] == true,
    dailyStockLimit: json['dailyStockLimit'] is int
        ? json['dailyStockLimit'] as int
        : null,
    dailyStockUsed: json['dailyStockUsed'] is int
        ? json['dailyStockUsed'] as int
        : 0,
  );

  final String id;
  final String name;
  final String description;
  final int priceInCents;
  final String category;
  final String? photoUrl;
  final List<String> allergens;
  final bool isVegetarian;
  final bool isAvailable;
  final int? dailyStockLimit;
  final int dailyStockUsed;

  Dish toDomain() => Dish(
    id: id,
    name: name,
    description: description,
    priceInCents: priceInCents,
    category: category,
    photoUrl: photoUrl,
    allergens: allergens,
    isVegetarian: isVegetarian,
    isAvailable: isAvailable,
    dailyStockLimit: dailyStockLimit,
    dailyStockUsed: dailyStockUsed,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'priceInCents': priceInCents,
    'category': category,
    'photoUrl': photoUrl,
    'allergens': allergens,
    'isVegetarian': isVegetarian,
    'isAvailable': isAvailable,
    'dailyStockLimit': dailyStockLimit,
    'dailyStockUsed': dailyStockUsed,
  };
}
