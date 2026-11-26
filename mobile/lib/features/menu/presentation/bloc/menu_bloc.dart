import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:campus_eats_mobile/features/menu/domain/get_menu.dart';

import 'menu_event.dart';
import 'menu_state.dart';

class MenuBloc extends Bloc<MenuEvent, MenuState> {
  MenuBloc({required GetMenu getMenu})
    : _getMenu = getMenu,
      super(const MenuLoading()) {
    on<MenuRequested>(_onRequested);
    on<MenuRefreshRequested>(_onRequested);
    on<DishFilterChanged>(_onFilterChanged);
  }

  final GetMenu _getMenu;
  int _requestVersion = 0;

  Future<void> _onRequested(MenuEvent event, Emitter<MenuState> emit) async {
    final date = event is MenuRequested
        ? event.date
        : (event as MenuRefreshRequested).date;
    final previous = state;
    final selectedCategory =
        previous is MenuContent && previous.menu.date == date
        ? previous.selectedCategory
        : null;
    final requestVersion = ++_requestVersion;
    emit(const MenuLoading());
    final cached = await _getMenu.getCached(date);
    if (requestVersion != _requestVersion) return;
    if (cached.menu != null && cached.failure == null) {
      emit(
        MenuLoaded(
          menu: cached.menu!,
          selectedCategory: selectedCategory,
          isRefreshing: true,
        ),
      );
    }

    final result = await _getMenu(date);
    if (requestVersion != _requestVersion) return;
    if (result.menu != null) {
      if (result.menu!.dishes.isEmpty) {
        emit(MenuEmpty(date));
      } else {
        emit(
          MenuLoaded(
            menu: result.menu!,
            selectedCategory: selectedCategory,
            cacheFailure: result.failure,
          ),
        );
      }
      return;
    }
    if (result.failure != null) {
      if (cached.menu != null && cached.cachedAt != null) {
        emit(
          MenuOfflineLoaded(
            menu: cached.menu!,
            lastUpdated: cached.cachedAt!,
            selectedCategory: selectedCategory,
          ),
        );
      } else {
        emit(MenuFailure(date, cached.failure ?? result.failure!));
      }
      return;
    }
    emit(MenuEmpty(date));
  }

  void _onFilterChanged(DishFilterChanged event, Emitter<MenuState> emit) {
    final current = state;
    if (current is MenuLoaded) {
      emit(
        current.copyWith(
          selectedCategory: event.category,
          clearCategory: event.category == null,
        ),
      );
    } else if (current is MenuOfflineLoaded) {
      emit(
        current.copyWith(
          selectedCategory: event.category,
          clearCategory: event.category == null,
        ),
      );
    }
  }
}
