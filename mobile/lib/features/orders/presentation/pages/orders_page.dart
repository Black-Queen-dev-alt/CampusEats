import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:campus_eats_mobile/app/di/injection.dart';
import 'package:campus_eats_mobile/core/theme/app_spacing.dart';
import 'package:campus_eats_mobile/core/widgets/state_view.dart';
import 'package:campus_eats_mobile/features/orders/domain/order.dart';
import 'package:campus_eats_mobile/features/orders/presentation/bloc/orders_bloc.dart';
import 'package:campus_eats_mobile/features/orders/presentation/bloc/orders_event.dart';
import 'package:campus_eats_mobile/features/orders/presentation/bloc/orders_state.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late final OrdersBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = getIt<OrdersBloc>()..add(const OrdersRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mes commandes'),
          actions: [
            IconButton(
              tooltip: 'Choisir un créneau',
              onPressed: () => context.push('/orders/checkout/slots'),
              icon: const Icon(Icons.schedule_rounded),
            ),
          ],
        ),
        body: BlocBuilder<OrdersBloc, OrdersState>(
          builder: (context, state) {
            final isLoading = state is OrdersLoading;
            final isEmpty = state is OrdersEmpty;
            final failure = state is OrdersFailure ? state.failure : null;
            final list = state is OrdersListLoaded ? state.orders : const [];
            final hasMore = state is OrdersListLoaded ? state.hasMore : false;
            final isLoadingMore = state is OrdersListLoaded
                ? state.isLoadingMore
                : false;
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.m),
              child: StateView(
                isLoading: isLoading,
                isEmpty: isEmpty,
                failure: failure,
                onRetry: () => _bloc.add(const OrdersRequested()),
                emptyTitle: 'Aucune commande',
                emptyMessage: 'Vous n’avez pas encore réservé de repas.',
                emptyActionLabel: 'Voir le menu',
                onEmptyAction: () => context.go('/menu'),
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification.metrics.pixels >=
                            notification.metrics.maxScrollExtent - 200 &&
                        hasMore &&
                        !isLoadingMore) {
                      _bloc.add(const LoadNextOrdersPage());
                    }
                    return false;
                  },
                  child: ListView.builder(
                    itemCount: list.length + 1,
                    itemBuilder: (context, index) {
                      if (index == list.length) {
                        if (isLoadingMore) {
                          return const Padding(
                            padding: EdgeInsets.all(AppSpacing.m),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (!hasMore) {
                          return const Padding(
                            padding: EdgeInsets.all(AppSpacing.m),
                            child: Center(
                              child: Text(
                                'Fin de l’historique',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }
                      final order = list[index];
                      final total =
                          '${(order.total / 100).toStringAsFixed(2).replaceAll('.', ',')} €';
                      return Card(
                        child: ListTile(
                          minVerticalPadding: AppSpacing.m,
                          onTap: () => context.push('/orders/${order.id}'),
                          title: Text(
                            'Commande ${order.number}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            '${order.timeSlotLabel}\n${order.status.label}',
                          ),
                          isThreeLine: true,
                          trailing: Text(
                            total,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    const steps = <(OrderStatus, String)>[
      (OrderStatus.received, 'Reçue'),
      (OrderStatus.preparing, 'Préparation'),
      (OrderStatus.ready, 'Prête'),
      (OrderStatus.collected, 'Retirée'),
    ];
    final activeIndex = switch (status) {
      OrderStatus.received => 0,
      OrderStatus.preparing => 1,
      OrderStatus.ready => 2,
      OrderStatus.collected => 3,
      OrderStatus.cancelled || OrderStatus.unknown => -1,
    };
    if (status == OrderStatus.cancelled) {
      return const Text(
        'Statut : Annulée',
        style: TextStyle(fontWeight: FontWeight.w700),
      );
    }
    return Row(
      children: [
        for (var index = 0; index < steps.length; index++) ...[
          if (index > 0)
            Expanded(
              child: Container(
                height: 2,
                color: index <= activeIndex
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).disabledColor,
              ),
            ),
          Expanded(
            flex: 2,
            child: Semantics(
              label: steps[index].$2,
              child: Column(
                children: [
                  Icon(
                    index <= activeIndex
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: index <= activeIndex
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).disabledColor,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    steps[index].$2,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage({super.key, required this.orderId});
  final String orderId;

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  late final OrdersBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = getIt<OrdersBloc>()..add(OrderDetailsRequested(widget.orderId));
  }

  String _formatPrice(int centimes) =>
      '${(centimes / 100).toStringAsFixed(2).replaceAll('.', ',')} €';

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        appBar: AppBar(title: const Text('Détail de la commande')),
        body: BlocConsumer<OrdersBloc, OrdersState>(
          listener: (context, state) {
            if (state is OrderDetailLoaded && state.failure != null) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.failure!.message)));
            }
          },
          builder: (context, state) {
            if (state is OrdersLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is OrdersFailure) {
              return StateView(
                failure: state.failure,
                onRetry: () => _bloc.add(OrderDetailsRequested(widget.orderId)),
              );
            }
            if (state is! OrderDetailLoaded) {
              return const SizedBox.shrink();
            }
            final order = state.order;
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.m),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Commande ${order.number}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.s),
                        Text('Créneau : ${order.timeSlotLabel}'),
                        Text('Statut : ${order.status.label}'),
                        const SizedBox(height: AppSpacing.s),
                        _StatusTimeline(status: order.status),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
                Card(
                  child: Column(
                    children: [
                      for (final item in order.items)
                        ListTile(
                          title: Text(item.name),
                          subtitle: Text('Quantité : ${item.quantity}'),
                          trailing: Text(_formatPrice(item.subtotal)),
                        ),
                      const Divider(),
                      ListTile(
                        title: const Text('Total'),
                        trailing: Text(
                          _formatPrice(order.total),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
                if (order.qrValue != null) ...[
                  const SizedBox(height: AppSpacing.m),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.qr_code_2_rounded),
                      title: const Text('Code de retrait'),
                      subtitle: Text(order.qrValue!),
                    ),
                  ),
                ],
                if (order.cancellationAllowed || state.isCancelling) ...[
                  const SizedBox(height: AppSpacing.l),
                  SizedBox(
                    height: AppSpacing.buttonHeight,
                    child: OutlinedButton(
                      onPressed: state.isCancelling
                          ? null
                          : () => _bloc.add(CancelOrderRequested(order.id)),
                      child: state.isCancelling
                          ? const Text('Annulation en cours...')
                          : const Text('Annuler la commande'),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
