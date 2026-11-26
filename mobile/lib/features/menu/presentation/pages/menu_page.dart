import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:campus_eats_mobile/app/di/injection.dart';
import 'package:campus_eats_mobile/core/errors/failure.dart';
import 'package:campus_eats_mobile/core/theme/app_spacing.dart';
import 'package:campus_eats_mobile/core/widgets/offline_banner.dart';
import 'package:campus_eats_mobile/core/widgets/skeleton.dart';
import 'package:campus_eats_mobile/core/widgets/state_view.dart';
import 'package:campus_eats_mobile/features/auth/presentation/widgets/logout_button.dart';
import 'package:campus_eats_mobile/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:campus_eats_mobile/features/cart/presentation/cubit/cart_state.dart';
import 'package:campus_eats_mobile/features/menu/domain/daily_menu.dart';
import 'package:campus_eats_mobile/features/menu/domain/dish.dart';
import 'package:campus_eats_mobile/features/menu/presentation/bloc/menu_bloc.dart';
import 'package:campus_eats_mobile/features/menu/presentation/bloc/menu_event.dart';
import 'package:campus_eats_mobile/features/menu/presentation/bloc/menu_state.dart';
import 'package:campus_eats_mobile/features/menu/presentation/pages/dish_detail_page.dart';
import 'package:campus_eats_mobile/features/menu/presentation/widgets/category_filter.dart';
import 'package:campus_eats_mobile/features/menu/presentation/widgets/day_selector.dart';
import 'package:campus_eats_mobile/features/menu/presentation/widgets/dish_card.dart';
import 'package:campus_eats_mobile/features/menu/presentation/widgets/menu_formatters.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  late final MenuBloc _menuBloc;
  late final CartCubit _cartCubit;
  DateTime _selectedDate = DateTime.now();

  String get _date => formatMenuDate(_selectedDate);

  @override
  void initState() {
    super.initState();
    _cartCubit = getIt<CartCubit>();
    _menuBloc = getIt<MenuBloc>()..add(MenuRequested(_date));
  }

  @override
  void dispose() {
    _menuBloc.close();
    super.dispose();
  }

  Future<void> _selectDate(DateTime date) async {
    final nextDate = formatMenuDate(date);
    if (nextDate == _date) return;
    if (_cartCubit.state.items.isNotEmpty &&
        _cartCubit.state.items.any((item) => item.date != nextDate)) {
      final clear = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Changer la date du panier ?'),
          content: const Text(
            'Votre panier est lié à une date. Le vider pour afficher le menu choisi ?',
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(false),
              child: const Text('Garder mon panier'),
            ),
            FilledButton(
              onPressed: () => context.pop(true),
              child: const Text('Vider et continuer'),
            ),
          ],
        ),
      );
      if (clear != true || !mounted) return;
      _cartCubit.clearCart();
    }
    setState(() => _selectedDate = date);
    _menuBloc.add(MenuRequested(nextDate));
  }

  Future<void> _refresh() async {
    _menuBloc.add(MenuRefreshRequested(_date));
    await _menuBloc.stream.firstWhere(
      (state) =>
          state is MenuOfflineLoaded ||
          state is MenuEmpty ||
          state is MenuFailure ||
          (state is MenuLoaded && !state.isRefreshing),
    );
  }

  void _openDish(DailyMenu menu, Dish dish) {
    context.push(
      '/menu/dishes/${dish.id}',
      extra: DishDetailArgs(dish: dish, menuId: menu.id, date: menu.date),
    );
  }

  void _addDish(DailyMenu menu, Dish dish) {
    _cartCubit.addItem(dish: dish, menuId: menu.id, date: menu.date);
    final message = _cartCubit.state.validationMessage;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message ?? '${dish.name} ajouté au panier')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _menuBloc,
      child: BlocListener<MenuBloc, MenuState>(
        listenWhen: (previous, current) {
          if (current is MenuLoaded && current.cacheFailure != null) {
            return true;
          }
          return current is MenuContent &&
              (previous is! MenuContent || previous.menu != current.menu);
        },
        listener: (context, state) {
          if (state is MenuContent) {
            _cartCubit.syncAvailability(state.menu);
          }
          if (state is MenuLoaded && state.cacheFailure != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.cacheFailure!.message)),
            );
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Menu du jour'),
            actions: [
              IconButton(
                tooltip: 'Rafraîchir le menu',
                onPressed: () => _menuBloc.add(MenuRefreshRequested(_date)),
                icon: const Icon(Icons.refresh_rounded),
              ),
              BlocBuilder<CartCubit, CartState>(
                bloc: _cartCubit,
                builder: (context, state) => IconButton(
                  tooltip: 'Ouvrir le panier',
                  onPressed: () => context.push('/cart'),
                  icon: Badge(
                    isLabelVisible: state.itemCount > 0,
                    label: Text('${state.itemCount}'),
                    child: const Icon(Icons.shopping_bag_outlined),
                  ),
                ),
              ),
              const LogoutButton(),
            ],
          ),
          body: Column(
            children: [
              DaySelector(selectedDate: _selectedDate, onSelected: _selectDate),
              const Divider(height: 1),
              Expanded(
                child: BlocBuilder<MenuBloc, MenuState>(
                  builder: (context, state) {
                    if (state is MenuLoading) {
                      return const StateView(
                        isLoading: true,
                        loadingPlaceholder: SkeletonList(),
                      );
                    }
                    if (state is MenuFailure) {
                      if (state.failure is NetworkFailure) {
                        return StateMessage(
                          icon: Icons.wifi_off_rounded,
                          title: 'Vous êtes hors ligne',
                          message: 'Aucun menu en cache n’est disponible pour cette date.',
                          primaryLabel: 'Réessayer',
                          onPrimary: () =>
                              _menuBloc.add(MenuRefreshRequested(_date)),
                        );
                      }
                      return StateView(
                        failure: state.failure,
                        onRetry: () =>
                            _menuBloc.add(MenuRefreshRequested(_date)),
                      );
                    }
                    if (state is MenuEmpty) {
                      return const StateView(
                        isEmpty: true,
                        emptyTitle: 'Aucun plat pour cette date',
                        emptyMessage: 'Aucun menu n’a été publié pour le jour sélectionné.',
                      );
                    }
                    if (state is MenuContent) {
                      return _MenuContents(
                        menu: state.menu,
                        selectedCategory: state.selectedCategory,
                        offline: state is MenuOfflineLoaded,
                        refreshing: state is MenuLoaded && state.isRefreshing,
                        lastUpdated: state is MenuOfflineLoaded
                            ? state.lastUpdated
                            : null,
                        onCategoryChanged: (category) =>
                            _menuBloc.add(DishFilterChanged(category)),
                        onRefresh: _refresh,
                        onOpenDish: (dish) => _openDish(state.menu, dish),
                        onAddDish: (dish) => _addDish(state.menu, dish),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuContents extends StatelessWidget {
  const _MenuContents({
    required this.menu,
    required this.selectedCategory,
    required this.offline,
    required this.refreshing,
    required this.lastUpdated,
    required this.onCategoryChanged,
    required this.onRefresh,
    required this.onOpenDish,
    required this.onAddDish,
  });

  final DailyMenu menu;
  final String? selectedCategory;
  final bool offline;
  final bool refreshing;
  final DateTime? lastUpdated;
  final ValueChanged<String?> onCategoryChanged;
  final Future<void> Function() onRefresh;
  final ValueChanged<Dish> onOpenDish;
  final ValueChanged<Dish> onAddDish;

  @override
  Widget build(BuildContext context) {
    final dishes = menu.dishes
        .where(
          (dish) =>
              selectedCategory == null || dish.category == selectedCategory,
        )
        .toList();
    final offlineMessage = lastUpdated == null
        ? 'Hors ligne — données de la dernière connexion'
        : 'Hors ligne — données de la dernière connexion (${lastUpdated!.day.toString().padLeft(2, '0')}/${lastUpdated!.month.toString().padLeft(2, '0')} à ${lastUpdated!.hour.toString().padLeft(2, '0')}:${lastUpdated!.minute.toString().padLeft(2, '0')})';

    return Column(
      children: [
        if (offline) OfflineBanner(message: offlineMessage),
        if (refreshing) const LinearProgressIndicator(minHeight: 2),
        CategoryFilter(
          selectedCategory: selectedCategory,
          onChanged: onCategoryChanged,
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: dishes.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: AppSpacing.xl),
                      Center(child: Text('Aucun plat dans cette catégorie.')),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.m),
                    itemCount: dishes.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.s),
                    itemBuilder: (context, index) {
                      final dish = dishes[index];
                      return DishCard(
                        dish: dish,
                        onTap: () => onOpenDish(dish),
                        onAdd: () => onAddDish(dish),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
