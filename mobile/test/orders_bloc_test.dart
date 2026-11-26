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
    'affiche les erreurs 422 sous les champs concernés',
    build: () {
      when(
        () => repository.createOrder(
          menuId: 'menu-1',
          timeSlotId: 'slot-1',
          items: any(named: 'items'),
        ),
      ).thenAnswer(
        (_) async => (
          value: null,
          failure: const ValidationFailure(
            'Données invalides',
            fieldErrors: {
              'lines.0.quantity': 'Quantité invalide',
              'slotId': 'Ce créneau est passé',
            },
          ),
        ),
      );
      return bloc;
    },
    act: (bloc) => bloc.add(
      const CreateOrderRequested(
        menuId: 'menu-1',
        timeSlotId: 'slot-1',
        items: [OrderItem(name: 'Plat', quantity: 0, unitPrice: 2500)],
      ),
    ),
    expect: () => [
      const OrderSubmitting(),
      isA<OrdersFailure>().having(
        (state) => state.failure,
        'validation failure',
        isA<ValidationFailure>()
            .having(
              (failure) => failure.fieldErrors['lines.0.quantity'],
              'quantity error',
              'Quantité invalide',
            )
            .having(
              (failure) => failure.fieldErrors['slotId'],
              'slot error',
              'Ce créneau est passé',
            ),
      ),
    ],
  );

  blocTest<OrdersBloc, OrdersState>(
    'traite un conflit 409 sans confirmer la commande',
    build: () {
      when(
        () => repository.createOrder(
          menuId: 'menu-1',
          timeSlotId: 'slot-full',
          items: any(named: 'items'),
        ),
      ).thenAnswer(
        (_) async => (
          value: null,
          failure: const ConflictFailure('Créneau complet', 'SLOT_FULL'),
        ),
      );
      return bloc;
    },
    act: (bloc) => bloc.add(
      const CreateOrderRequested(
        menuId: 'menu-1',
        timeSlotId: 'slot-full',
        items: [OrderItem(name: 'Plat', quantity: 1, unitPrice: 2500)],
      ),
    ),
    expect: () => [const OrderSubmitting(), isA<SlotConflict>()],
  );

  blocTest<OrdersBloc, OrdersState>(
    'ne traite pas un conflit qui ne concerne pas le créneau comme un conflit de créneau',
    build: () {
      when(
        () => repository.createOrder(
          menuId: 'menu-1',
          timeSlotId: 'slot-1',
          items: any(named: 'items'),
        ),
      ).thenAnswer(
        (_) async => (
          value: null,
          failure: const ConflictFailure(
            'Menu non publié',
            'MENU_NOT_PUBLISHED',
          ),
        ),
      );
      return bloc;
    },
    act: (bloc) => bloc.add(
      const CreateOrderRequested(
        menuId: 'menu-1',
        timeSlotId: 'slot-1',
        items: [OrderItem(name: 'Plat', quantity: 1, unitPrice: 2500)],
      ),
    ),
    expect: () => [
      const OrderSubmitting(),
      isA<OrdersFailure>().having(
        (state) => state.failure.message,
        'failure message',
        'Menu non publié',
      ),
    ],
  );

  blocTest<OrdersBloc, OrdersState>(
    'confirme la commande uniquement après le succès du dépôt',
    build: () {
      const order = Order(
        id: 'order-1',
        number: 'order-1',
        timeSlotId: 'slot-1',
        timeSlotLabel: '12:00 - 12:15',
        items: [],
        total: 0,
        status: OrderStatus.received,
      );
      when(
        () => repository.createOrder(
          menuId: 'menu-1',
          timeSlotId: 'slot-1',
          items: any(named: 'items'),
        ),
      ).thenAnswer((_) async => (value: order, failure: null));
      return bloc;
    },
    act: (bloc) => bloc.add(
      const CreateOrderRequested(
        menuId: 'menu-1',
        timeSlotId: 'slot-1',
        items: [
          OrderItem(
            dishId: 'dish-1',
            name: 'Plat',
            quantity: 1,
            unitPrice: 500,
          ),
        ],
      ),
    ),
    expect: () => [const OrderSubmitting(), isA<OrderCreated>()],
  );

  blocTest<OrdersBloc, OrdersState>(
    'restaure le détail de commande si le serveur refuse l’annulation',
    build: () {
      const order = Order(
        id: 'order-1',
        number: 'order-1',
        timeSlotId: 'slot-1',
        timeSlotLabel: '12:00 - 12:15',
        items: [],
        total: 0,
        status: OrderStatus.received,
      );
      when(
        () => repository.getOrder('order-1'),
      ).thenAnswer((_) async => (value: order, failure: null));
      when(() => repository.cancelOrder('order-1')).thenAnswer(
        (_) async => (
          value: null,
          failure: const ConflictFailure(
            'La période d’annulation est terminée',
          ),
        ),
      );
      return bloc;
    },
    act: (bloc) async {
      bloc.add(const OrderDetailsRequested('order-1'));
      await bloc.stream.firstWhere((state) => state is OrderDetailLoaded);
      bloc.add(const CancelOrderRequested('order-1'));
    },
    expect: () => [
      const OrdersLoading(),
      isA<OrderDetailLoaded>().having(
        (state) => state.isCancelling,
        'isCancelling',
        false,
      ),
      isA<OrderDetailLoaded>()
          .having(
            (state) => state.order.status,
            'optimistic status',
            OrderStatus.cancelled,
          )
          .having(
            (state) => state.order.cancellationAllowed,
            'cancellation disabled',
            false,
          )
          .having((state) => state.isCancelling, 'isCancelling', true),
      isA<OrderDetailLoaded>()
          .having((state) => state.order.status, 'status', OrderStatus.received)
          .having((state) => state.isCancelling, 'isCancelling', false)
          .having(
            (state) => state.failure?.message,
            'failure message',
            'La période d’annulation est terminée',
          ),
    ],
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

  blocTest<OrdersBloc, OrdersState>(
    'ignore une seconde demande de page pendant le chargement',
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
          hasMore: true,
          failure: null,
        ),
      );
      when(() => repository.getOrders(page: 2, limit: 10)).thenAnswer((
        _,
      ) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return (
          value: const [
            Order(
              id: '2',
              number: 'CE-2',
              timeSlotId: 'slot-2',
              timeSlotLabel: '12:15',
              items: [],
              total: 3000,
              status: OrderStatus.received,
            ),
          ],
          hasMore: false,
          failure: null,
        );
      });
      return bloc;
    },
    act: (bloc) async {
      bloc.add(const OrdersRequested());
      await bloc.stream.firstWhere((state) => state is OrdersListLoaded);
      bloc
        ..add(const LoadNextOrdersPage())
        ..add(const LoadNextOrdersPage());
      await Future<void>.delayed(const Duration(milliseconds: 100));
    },
    expect: () => [
      const OrdersLoading(),
      isA<OrdersListLoaded>(),
      isA<OrdersListLoaded>().having(
        (state) => state.isLoadingMore,
        'isLoadingMore',
        true,
      ),
      isA<OrdersListLoaded>().having(
        (state) => state.orders.length,
        'orders count',
        2,
      ),
    ],
    verify: (_) {
      verify(() => repository.getOrders(page: 2, limit: 10)).called(1);
    },
  );
}
