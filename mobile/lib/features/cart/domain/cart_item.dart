import 'package:equatable/equatable.dart';
import 'package:campus_eats_mobile/features/menu/domain/dish.dart';

class CartItem extends Equatable {
  const CartItem({
    required this.dish,
    required this.quantity,
    required this.menuId,
    required this.date,
  });

  final Dish dish;
  final int quantity;
  final String menuId;
  final String date;

  int get subtotal => dish.priceInCents * quantity;
  bool get canFulfill {
    if (!dish.isAvailable || !dish.hasStock) return false;
    final limit = dish.dailyStockLimit;
    return limit == null || quantity <= limit - dish.dailyStockUsed;
  }

  CartItem copyWith({Dish? dish, int? quantity}) => CartItem(
    dish: dish ?? this.dish,
    quantity: quantity ?? this.quantity,
    menuId: menuId,
    date: date,
  );

  @override
  List<Object?> get props => [dish, quantity, menuId, date];
}
