import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:campus_eats_mobile/app/di/injection.dart';
import 'package:campus_eats_mobile/core/errors/failure.dart';
import 'package:campus_eats_mobile/core/theme/app_spacing.dart';
import 'package:campus_eats_mobile/features/orders/domain/order.dart';
import 'package:campus_eats_mobile/features/orders/presentation/bloc/orders_bloc.dart';
import 'package:campus_eats_mobile/features/orders/presentation/bloc/orders_event.dart';
import 'package:campus_eats_mobile/features/orders/presentation/bloc/orders_state.dart';
import 'package:campus_eats_mobile/features/time_slots/domain/time_slot.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key, required this.slot});
  final TimeSlot slot;

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  static const demoItems = <OrderItem>[
    OrderItem(name: 'Riz sauce arachide', quantity: 1, unitPrice: 2500),
    OrderItem(name: 'Salade fraiche', quantity: 1, unitPrice: 1200),
  ];

  late final OrdersBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = getIt<OrdersBloc>();
  }

  String _formatPrice(int centimes) =>
      '${(centimes / 100).toStringAsFixed(2).replaceAll('.', ',')} €';

  Future<void> _showConflict(ConflictFailure failure) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Créneau indisponible'),
        content: Text(failure.message),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Choisir un autre créneau'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = demoItems.fold<int>(0, (sum, item) => sum + item.subtotal);
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        appBar: AppBar(title: const Text('Confirmer la commande')),
        body: BlocConsumer<OrdersBloc, OrdersState>(
          listener: (context, state) async {
            if (state is SlotConflict) {
              await _showConflict(state.failure);
              if (context.mounted) context.pop();
            } else if (state is OrderCreated) {
              if (context.mounted) {
                context.go('/orders/${state.order.id}');
              }
            } else if (state is OrdersFailure) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(state.failure.message)));
            }
          },
          builder: (context, state) {
            final isSubmitting = state is OrderSubmitting;
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
                          'Créneau',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.s),
                        Text(
                          '${widget.slot.startTime} - ${widget.slot.endTime}',
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${widget.slot.remaining} places disponibles',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.m),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    child: Column(
                      children: [
                        for (final item in demoItems)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(item.name),
                            subtitle: Text('Quantité : ${item.quantity}'),
                            trailing: Text(_formatPrice(item.subtotal)),
                          ),
                        const Divider(),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Total',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          trailing: Text(
                            _formatPrice(total),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.l),
                SizedBox(
                  height: AppSpacing.buttonHeight,
                  child: FilledButton(
                    onPressed: isSubmitting
                        ? null
                        : () => _bloc.add(
                            CreateOrderRequested(
                              timeSlotId: widget.slot.id,
                              items: demoItems,
                            ),
                          ),
                    child: isSubmitting
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : const Text('Confirmer la commande'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
