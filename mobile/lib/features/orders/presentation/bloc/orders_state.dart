import 'package:equatable/equatable.dart';
import 'package:campus_eats_mobile/core/errors/failure.dart';
import 'package:campus_eats_mobile/features/orders/domain/order.dart';

abstract class OrdersState extends Equatable {
  const OrdersState();
  @override
  List<Object?> get props => [];
}

class OrdersLoading extends OrdersState {
  const OrdersLoading();
}

class OrdersEmpty extends OrdersState {
  const OrdersEmpty();
}

class OrdersListLoaded extends OrdersState {
  const OrdersListLoaded({
    required this.orders,
    required this.hasMore,
    this.isLoadingMore = false,
  });
  final List<Order> orders;
  final bool hasMore;
  final bool isLoadingMore;

  @override
  List<Object?> get props => [orders, hasMore, isLoadingMore];
}

class OrderDetailLoaded extends OrdersState {
  const OrderDetailLoaded(
    this.order, {
    this.isCancelling = false,
    this.failure,
  });
  final Order order;
  final bool isCancelling;
  final Failure? failure;

  @override
  List<Object?> get props => [order, isCancelling, failure];
}

class OrderSubmitting extends OrdersState {
  const OrderSubmitting();
}

class OrderCreated extends OrdersState {
  const OrderCreated(this.order);
  final Order order;
  @override
  List<Object?> get props => [order];
}

class SlotConflict extends OrdersState {
  const SlotConflict(this.failure);
  final ConflictFailure failure;
  @override
  List<Object?> get props => [failure];
}

class OrdersFailure extends OrdersState {
  const OrdersFailure(this.failure);
  final Failure failure;
  @override
  List<Object?> get props => [failure];
}
