import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:campus_eats_mobile/core/errors/failure.dart';
import 'package:campus_eats_mobile/features/orders/domain/cancel_order.dart';
import 'package:campus_eats_mobile/features/orders/domain/create_order.dart';
import 'package:campus_eats_mobile/features/orders/domain/get_order.dart';
import 'package:campus_eats_mobile/features/orders/domain/get_orders.dart';
import 'package:campus_eats_mobile/features/orders/domain/order.dart';

import 'orders_event.dart';
import 'orders_state.dart';

class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  OrdersBloc({
    required GetOrders getOrders,
    required GetOrder getOrder,
    required CreateOrder createOrder,
    required CancelOrder cancelOrder,
  }) : _getOrders = getOrders,
       _getOrder = getOrder,
       _createOrder = createOrder,
       _cancelOrder = cancelOrder,
       super(const OrdersLoading()) {
    on<OrdersRequested>(_onOrdersRequested);
    on<LoadNextOrdersPage>(_onLoadNext, transformer: droppable());
    on<OrderDetailsRequested>(_onDetailsRequested);
    on<CreateOrderRequested>(_onCreateOrder, transformer: droppable());
    on<CancelOrderRequested>(_onCancelOrder, transformer: droppable());
  }

  final GetOrders _getOrders;
  final GetOrder _getOrder;
  final CreateOrder _createOrder;
  final CancelOrder _cancelOrder;

  int _page = 1;
  bool _hasMore = true;
  bool _isLoadingNext = false;

  Future<void> _onOrdersRequested(
    OrdersRequested event,
    Emitter<OrdersState> emit,
  ) async {
    _page = 1;
    _hasMore = true;
    emit(const OrdersLoading());
    final result = await _getOrders(page: _page, limit: 10);
    if (result.failure != null) {
      emit(OrdersFailure(result.failure!));
    } else if (result.value.isEmpty) {
      emit(const OrdersEmpty());
    } else {
      _hasMore = result.hasMore;
      emit(OrdersListLoaded(orders: result.value, hasMore: _hasMore));
    }
  }

  Future<void> _onLoadNext(
    LoadNextOrdersPage event,
    Emitter<OrdersState> emit,
  ) async {
    final current = state;
    if (!_hasMore || _isLoadingNext) return;
    if (current is! OrdersListLoaded) return;
    _isLoadingNext = true;
    emit(
      OrdersListLoaded(
        orders: current.orders,
        hasMore: true,
        isLoadingMore: true,
      ),
    );
    final nextPage = _page + 1;
    final result = await _getOrders(page: nextPage, limit: 10);
    _isLoadingNext = false;
    if (result.failure != null) {
      emit(OrdersListLoaded(orders: current.orders, hasMore: _hasMore));
      emit(OrdersFailure(result.failure!));
      return;
    }
    _page = nextPage;
    _hasMore = result.hasMore;
    emit(
      OrdersListLoaded(
        orders: [...current.orders, ...result.value],
        hasMore: _hasMore,
      ),
    );
  }

  Future<void> _onDetailsRequested(
    OrderDetailsRequested event,
    Emitter<OrdersState> emit,
  ) async {
    emit(const OrdersLoading());
    final result = await _getOrder(event.id);
    if (result.failure != null) {
      emit(OrdersFailure(result.failure!));
    } else if (result.value != null) {
      emit(OrderDetailLoaded(result.value!));
    } else {
      emit(const OrdersFailure(ServerFailure('Commande introuvable')));
    }
  }

  Future<void> _onCreateOrder(
    CreateOrderRequested event,
    Emitter<OrdersState> emit,
  ) async {
    emit(const OrderSubmitting());
    final result = await _createOrder(
      menuId: event.menuId,
      timeSlotId: event.timeSlotId,
      items: event.items,
    );
    if (result.failure is ConflictFailure &&
        _isSlotConflict(result.failure! as ConflictFailure)) {
      emit(SlotConflict(result.failure! as ConflictFailure));
    } else if (result.failure != null) {
      emit(OrdersFailure(result.failure!));
    } else if (result.value != null) {
      emit(OrderCreated(result.value!));
    } else {
      emit(
        const OrdersFailure(
          ServerFailure('Confirmation de commande impossible'),
        ),
      );
    }
  }

  bool _isSlotConflict(ConflictFailure failure) {
    return const {
      'SLOT_FULL',
      'SLOT_STARTED',
      'TIME_SLOT_COMPLETED',
    }.contains(failure.code);
  }

  Future<void> _onCancelOrder(
    CancelOrderRequested event,
    Emitter<OrdersState> emit,
  ) async {
    final current = state;
    if (current is! OrderDetailLoaded) return;
    final snapshot = current.order;
    emit(
      OrderDetailLoaded(
        snapshot.copyWith(status: OrderStatus.cancelled, canCancel: false),
        isCancelling: true,
      ),
    );

    final result = await _cancelOrder(event.id);
    if (result.failure != null) {
      emit(
        OrderDetailLoaded(
          snapshot,
          isCancelling: false,
          failure: result.failure,
        ),
      );
    } else if (result.value != null) {
      emit(
        OrderDetailLoaded(
          result.value!.copyWith(timeSlotLabel: snapshot.timeSlotLabel),
          isCancelling: false,
        ),
      );
    } else {
      emit(
        OrderDetailLoaded(
          snapshot,
          isCancelling: false,
          failure: const ServerFailure('Annulation de la commande impossible'),
        ),
      );
    }
  }
}
