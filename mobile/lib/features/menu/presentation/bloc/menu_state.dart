import 'package:equatable/equatable.dart';
import 'package:campus_eats_mobile/core/errors/failure.dart';
import 'package:campus_eats_mobile/features/menu/domain/daily_menu.dart';

abstract class MenuState extends Equatable {
  const MenuState();
  @override
  List<Object?> get props => [];
}

class MenuLoading extends MenuState {
  const MenuLoading();
}

class MenuEmpty extends MenuState {
  const MenuEmpty(this.date);
  final String date;
  @override
  List<Object?> get props => [date];
}

class MenuFailure extends MenuState {
  const MenuFailure(this.date, this.failure);
  final String date;
  final Failure failure;
  @override
  List<Object?> get props => [date, failure];
}

abstract class MenuContent extends MenuState {
  const MenuContent({
    required this.menu,
    this.selectedCategory,
    this.isRefreshing = false,
  });

  final DailyMenu menu;
  final String? selectedCategory;
  final bool isRefreshing;
}

class MenuLoaded extends MenuContent {
  const MenuLoaded({
    required super.menu,
    super.selectedCategory,
    super.isRefreshing = false,
    this.cacheFailure,
  });

  final Failure? cacheFailure;

  MenuLoaded copyWith({String? selectedCategory, bool clearCategory = false}) =>
      MenuLoaded(
        menu: menu,
        selectedCategory: clearCategory
            ? null
            : selectedCategory ?? this.selectedCategory,
        isRefreshing: isRefreshing,
        cacheFailure: cacheFailure,
      );

  @override
  List<Object?> get props => [
    menu,
    selectedCategory,
    isRefreshing,
    cacheFailure,
  ];
}

class MenuOfflineLoaded extends MenuContent {
  const MenuOfflineLoaded({
    required super.menu,
    required this.lastUpdated,
    super.selectedCategory,
  });

  final DateTime lastUpdated;

  MenuOfflineLoaded copyWith({
    String? selectedCategory,
    bool clearCategory = false,
  }) => MenuOfflineLoaded(
    menu: menu,
    lastUpdated: lastUpdated,
    selectedCategory: clearCategory
        ? null
        : selectedCategory ?? this.selectedCategory,
  );

  @override
  List<Object?> get props => [menu, lastUpdated, selectedCategory];
}
