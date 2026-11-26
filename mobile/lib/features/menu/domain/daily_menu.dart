import 'package:equatable/equatable.dart';
import 'package:campus_eats_mobile/features/menu/domain/dish.dart';

class DailyMenu extends Equatable {
  const DailyMenu({required this.id, required this.date, required this.dishes});

  final String id;
  final String date;
  final List<Dish> dishes;

  @override
  List<Object?> get props => [id, date, dishes];
}
