import 'package:equatable/equatable.dart';
import 'package:campus_eats_mobile/features/cart/domain/cart_item.dart';

class CartState extends Equatable {
  const CartState({this.items = const [], this.validationMessage});

  final List<CartItem> items;
  final String? validationMessage;

  int get totalInCents => items.fold(0, (total, item) => total + item.subtotal);

  int get itemCount => items.fold(0, (count, item) => count + item.quantity);

  bool get isEmpty => items.isEmpty;

  @override
  List<Object?> get props => [items, validationMessage];
}
