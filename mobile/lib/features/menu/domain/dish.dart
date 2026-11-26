import 'package:equatable/equatable.dart';

class Dish extends Equatable {
  const Dish({
    required this.id,
    required this.name,
    required this.description,
    required this.priceInCents,
    required this.category,
    required this.allergens,
    required this.isVegetarian,
    required this.isAvailable,
    this.photoUrl,
    this.dailyStockLimit,
    this.dailyStockUsed = 0,
  });

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

  bool get hasStock =>
      dailyStockLimit == null || dailyStockUsed < dailyStockLimit!;

  Dish copyWith({
    bool? isAvailable,
    int? dailyStockLimit,
    int? dailyStockUsed,
    String? photoUrl,
  }) => Dish(
    id: id,
    name: name,
    description: description,
    priceInCents: priceInCents,
    category: category,
    allergens: allergens,
    isVegetarian: isVegetarian,
    isAvailable: isAvailable ?? this.isAvailable,
    photoUrl: photoUrl ?? this.photoUrl,
    dailyStockLimit: dailyStockLimit ?? this.dailyStockLimit,
    dailyStockUsed: dailyStockUsed ?? this.dailyStockUsed,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    priceInCents,
    category,
    photoUrl,
    allergens,
    isVegetarian,
    isAvailable,
    dailyStockLimit,
    dailyStockUsed,
  ];
}
