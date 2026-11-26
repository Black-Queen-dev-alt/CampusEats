import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:campus_eats_mobile/features/cart/domain/cart_item.dart';
import 'package:campus_eats_mobile/features/cart/presentation/cubit/cart_state.dart';
import 'package:campus_eats_mobile/features/menu/domain/daily_menu.dart';
import 'package:campus_eats_mobile/features/menu/domain/dish.dart';

class CartCubit extends Cubit<CartState> {
  CartCubit() : super(const CartState());

  void addItem({
    required Dish dish,
    required String menuId,
    required String date,
  }) {
    if (!dish.isAvailable || !dish.hasStock) {
      emit(
        CartState(
          items: state.items,
          validationMessage: 'Ce plat n’est plus disponible.',
        ),
      );
      return;
    }
    if (state.items.isNotEmpty &&
        state.items.any((item) => item.date != date)) {
      emit(
        CartState(
          items: state.items,
          validationMessage:
              'Le panier contient des plats pour une autre date.',
        ),
      );
      return;
    }
    final index = state.items.indexWhere((item) => item.dish.id == dish.id);
    final items = [...state.items];
    if (index == -1) {
      items.add(CartItem(dish: dish, quantity: 1, menuId: menuId, date: date));
    } else {
      final item = items[index];
      final maxQuantity = dish.dailyStockLimit == null
          ? null
          : dish.dailyStockLimit! - dish.dailyStockUsed;
      if (maxQuantity != null && item.quantity >= maxQuantity) {
        emit(
          CartState(
            items: state.items,
            validationMessage: 'Le stock disponible pour ce plat est atteint.',
          ),
        );
        return;
      }
      items[index] = item.copyWith(dish: dish, quantity: item.quantity + 1);
    }
    emit(CartState(items: items));
  }

  void removeItem(String dishId) {
    emit(
      CartState(
        items: state.items.where((item) => item.dish.id != dishId).toList(),
      ),
    );
  }

  void changeQuantity(String dishId, int quantity) {
    if (quantity <= 0) {
      removeItem(dishId);
      return;
    }
    final index = state.items.indexWhere((item) => item.dish.id == dishId);
    if (index == -1) return;
    final item = state.items[index];
    final maxQuantity = item.dish.dailyStockLimit == null
        ? null
        : item.dish.dailyStockLimit! - item.dish.dailyStockUsed;
    if (!item.dish.isAvailable ||
        (maxQuantity != null && quantity > maxQuantity)) {
      emit(
        CartState(
          items: state.items,
          validationMessage: 'La quantité dépasse le stock disponible.',
        ),
      );
      return;
    }
    final items = [...state.items];
    items[index] = item.copyWith(quantity: quantity);
    emit(CartState(items: items));
  }

  void clearCart() => emit(const CartState());

  void syncAvailability(DailyMenu menu) {
    if (state.items.isEmpty || state.items.first.date != menu.date) return;
    final dishes = {for (final dish in menu.dishes) dish.id: dish};
    final updated = state.items
        .map(
          (item) => item.copyWith(
            dish:
                dishes[item.dish.id] ?? item.dish.copyWith(isAvailable: false),
          ),
        )
        .toList();
    emit(CartState(items: updated));
  }
}
