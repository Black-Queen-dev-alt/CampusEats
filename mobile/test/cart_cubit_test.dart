import 'package:flutter_test/flutter_test.dart';
import 'package:campus_eats_mobile/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:campus_eats_mobile/features/menu/domain/dish.dart';

const _dish = Dish(
  id: 'dish-1',
  name: 'Riz',
  description: 'Plat du jour',
  priceInCents: 1250,
  category: 'plat',
  allergens: [],
  isVegetarian: false,
  isAvailable: true,
  dailyStockLimit: 5,
  dailyStockUsed: 2,
);

void main() {
  late CartCubit cart;

  setUp(() => cart = CartCubit());
  tearDown(() => cart.close());

  test('ajoute les plats et recalcule le total des quantités', () {
    cart.addItem(dish: _dish, menuId: 'menu-1', date: '2026-11-26');
    cart.addItem(dish: _dish, menuId: 'menu-1', date: '2026-11-26');

    expect(cart.state.items.single.quantity, 2);
    expect(cart.state.itemCount, 2);
    expect(cart.state.totalInCents, 2500);
  });

  test('ne permet pas de dépasser le stock connu', () {
    for (var i = 0; i < 4; i++) {
      cart.addItem(dish: _dish, menuId: 'menu-1', date: '2026-11-26');
    }

    expect(cart.state.items.single.quantity, 3);
    expect(cart.state.validationMessage, isNotNull);
  });

  test('refuse de mélanger des dates et permet de vider le panier', () {
    cart.addItem(dish: _dish, menuId: 'menu-1', date: '2026-11-26');
    cart.addItem(dish: _dish, menuId: 'menu-2', date: '2026-11-27');
    expect(cart.state.items.single.date, '2026-11-26');
    expect(cart.state.validationMessage, isNotNull);

    cart.clearCart();
    expect(cart.state.isEmpty, isTrue);
    expect(cart.state.totalInCents, 0);
  });
}
