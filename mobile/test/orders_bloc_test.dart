import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:campus_eats_mobile/core/errors/failure.dart';
import 'package:campus_eats_mobile/features/orders/domain/cancel_order.dart';
import 'package:campus_eats_mobile/features/orders/domain/create_order.dart';
import 'package:campus_eats_mobile/features/orders/domain/get_order.dart';
import 'package:campus_eats_mobile/features/orders/domain/get_orders.dart';
import 'package:campus_eats_mobile/features/orders/domain/order.dart';
import 'package:campus_eats_mobile/features/orders/domain/orders_repository.dart';
import 'package:campus_eats_mobile/features/orders/presentation/bloc/orders_bloc.dart';
import 'package:campus_eats_mobile/features/orders/presentation/bloc/orders_event.dart';
import 'package:campus_eats_mobile/features/orders/presentation/bloc/orders_state.dart';

class _MockOrdersRepository extends Mock implements OrdersRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(<OrderItem>[]);
  });

  late _MockOrdersRepository repository;
  late OrdersBloc bloc;

  setUp(() {
    repository = _MockOrdersRepository();
    bloc = OrdersBloc(
      getOrders: GetOrders(repository),
      getOrder: GetOrder(repository),
      createOrder: CreateOrder(repository),
      cancelOrder: CancelOrder(repository),
    );
  });

  tearDown(() => bloc.close());

  blocTest<OrdersBloc, OrdersState>(
    'traite un conflit 409 sans confirmer la commande',
    build: () {
      when(
        () => repository.createOrder(
          timeSlotId: 'slot-full',
          items: any(named: 'items'),
        ),
      ).thenAnswer(
        (_) async =>
            (value: null, failure: const ConflictFailure('Créneau complet')),
      );
      return bloc;
    },
    act: (bloc) => bloc.add(
      const CreateOrderRequested(
        timeSlotId: 'slot-full',
        items: [OrderItem(name: 'Plat', quantity: 1, unitPrice: 2500)],
      ),
    ),
    expect: () => [const OrderSubmitting(), isA<SlotConflict>()],
  );

  blocTest<OrdersBloc, OrdersState>(
    'charge une liste paginée',
    build: () {
      when(() => repository.getOrders(page: 1, limit: 10)).thenAnswer(
        (_) async => (
          value: const [
            Order(
              id: '1',
              number: 'CE-1',
              timeSlotId: 'slot-1',
              timeSlotLabel: '12:00',
              items: [],
              total: 2500,
              status: OrderStatus.received,
            ),
          ],
          hasMore: false,
          failure: null,
        ),
      );
      return bloc;
    },
    act: (bloc) => bloc.add(const OrdersRequested()),
    expect: () => [const OrdersLoading(), isA<OrdersListLoaded>()],
  );
}
