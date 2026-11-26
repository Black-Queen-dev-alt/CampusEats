import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:campus_eats_mobile/features/menu/data/menu_dto.dart';
import 'package:campus_eats_mobile/features/menu/data/menu_local_data_source.dart';
import 'package:campus_eats_mobile/features/menu/domain/dish.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('conserve le cache par date et les montants en centimes', () async {
    const dataSource = MenuLocalDataSource();
    const menu = MenuDto(
      id: 'menu-1',
      date: '2026-11-26',
      dishes: [
        Dish(
          id: 'dish-1',
          name: 'Riz',
          description: 'Plat du jour',
          priceInCents: 1250,
          category: 'plat',
          photoUrl: null,
          allergens: ['arachides'],
          isVegetarian: false,
          isAvailable: true,
        ),
      ],
    );

    expect(await dataSource.saveMenu(menu.date, menu), isTrue);
    final cached = await dataSource.getMenu(menu.date);
    final otherDate = await dataSource.getMenu('2026-11-27');

    expect(cached.menu?.toDomain().dishes.single.priceInCents, 1250);
    expect(cached.menu?.toDomain().dishes.single.allergens, ['arachides']);
    expect(cached.cachedAt, isNotNull);
    expect(otherDate.menu, isNull);
  });
}
