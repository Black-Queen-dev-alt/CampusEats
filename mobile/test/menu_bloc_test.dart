import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:campus_eats_mobile/core/errors/failure.dart';
import 'package:campus_eats_mobile/features/menu/data/menu_dto.dart';
import 'package:campus_eats_mobile/features/menu/domain/daily_menu.dart';
import 'package:campus_eats_mobile/features/menu/domain/dish.dart';
import 'package:campus_eats_mobile/features/menu/domain/get_menu.dart';
import 'package:campus_eats_mobile/features/menu/domain/menu_repository.dart';
import 'package:campus_eats_mobile/features/menu/presentation/bloc/menu_bloc.dart';
import 'package:campus_eats_mobile/features/menu/presentation/bloc/menu_event.dart';
import 'package:campus_eats_mobile/features/menu/presentation/bloc/menu_state.dart';

class _MockMenuRepository extends Mock implements MenuRepository {}

const _menu = DailyMenu(
  id: 'menu-1',
  date: '2026-11-26',
  dishes: [
    Dish(
      id: 'dish-1',
      name: 'Riz',
      description: 'Plat du jour',
      priceInCents: 1250,
      category: 'plat',
      allergens: [],
      isVegetarian: false,
      isAvailable: true,
    ),
  ],
);

void main() {
  late _MockMenuRepository repository;
  late MenuBloc bloc;

  setUp(() {
    repository = _MockMenuRepository();
    bloc = MenuBloc(getMenu: GetMenu(repository));
  });

  tearDown(() => bloc.close());

  blocTest<MenuBloc, MenuState>(
    'affiche le cache immédiatement puis les données actualisées',
    build: () {
      when(() => repository.getCachedMenu('2026-11-26')).thenAnswer(
        (_) async =>
            (menu: _menu, cachedAt: DateTime(2026, 11, 25), failure: null),
      );
      when(() => repository.getMenu('2026-11-26'))
          .thenAnswer((_) async => (menu: _menu, failure: null));
      return bloc;
    },
    act: (bloc) => bloc.add(const MenuRequested('2026-11-26')),
    expect: () => [
      const MenuLoading(),
      isA<MenuLoaded>().having(
        (state) => state.isRefreshing,
        'refreshing',
        true,
      ),
      isA<MenuLoaded>().having(
        (state) => state.isRefreshing,
        'refreshing',
        false,
      ),
    ],
  );

  blocTest<MenuBloc, MenuState>(
    'garde le dernier menu quand le réseau est indisponible',
    build: () {
      when(() => repository.getCachedMenu('2026-11-26')).thenAnswer(
        (_) async =>
            (menu: _menu, cachedAt: DateTime(2026, 11, 25), failure: null),
      );
      when(
        () => repository.getMenu('2026-11-26'),
      ).thenAnswer((_) async => (menu: null, failure: const NetworkFailure()));
      return bloc;
    },
    act: (bloc) => bloc.add(const MenuRequested('2026-11-26')),
    expect: () => [
      const MenuLoading(),
      isA<MenuLoaded>(),
      isA<MenuOfflineLoaded>(),
    ],
  );

  blocTest<MenuBloc, MenuState>(
    'représente une date sans menu comme un état vide',
    build: () {
      when(() => repository.getCachedMenu('2026-11-26'))
          .thenAnswer((_) async => (menu: null, cachedAt: null, failure: null));
      when(() => repository.getMenu('2026-11-26'))
          .thenAnswer((_) async => (menu: null, failure: null));
      return bloc;
    },
    act: (bloc) => bloc.add(const MenuRequested('2026-11-26')),
    expect: () => [const MenuLoading(), const MenuEmpty('2026-11-26')],
  );

  test('mappe le menu API et conserve le prix entier en centimes', () {
    final menu = MenuDto.fromJson({
      'id': 'menu-1',
      'date': '2026-11-26',
      'items': [
        {
          'isAvailable': true,
          'dailyStockLimit': 8,
          'dailyStockUsed': 2,
          'dishId': {
            'id': 'dish-1',
            'name': 'Riz',
            'description': 'Plat du jour',
            'priceInCents': 1250,
            'category': 'plat',
            'allergens': ['arachides'],
            'isVegetarian': false,
          },
        },
      ],
    }).toDomain();

    expect(menu.dishes.single.priceInCents, 1250);
    expect(menu.dishes.single.allergens, ['arachides']);
    expect(menu.dishes.single.dailyStockLimit, 8);
    expect(menu.dishes.single.dailyStockUsed, 2);
  });
}
