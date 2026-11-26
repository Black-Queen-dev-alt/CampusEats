import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:campus_eats_mobile/app/di/injection.dart';
import 'package:campus_eats_mobile/core/errors/failure.dart';
import 'package:campus_eats_mobile/core/theme/app_spacing.dart';
import 'package:campus_eats_mobile/features/cart/presentation/cubit/cart_cubit.dart';
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
  late final OrdersBloc _bloc;
  late final CartCubit _cart;

  @override
  void initState() {
    super.initState();
    _bloc = getIt<OrdersBloc>();
    _cart = getIt<CartCubit>();
  }

  String _formatPrice(int centimes) =>
      '${(centimes / 100).toStringAsFixed(2).replaceAll('.', ',')} €';

  List<String> _fieldErrors(OrdersState state, String field) {
    if (state is! OrdersFailure || state.failure is! ValidationFailure) {
      return const [];
    }
    final errors = (state.failure as ValidationFailure).fieldErrors;
    return errors.entries
        .where(
          (entry) =>
              entry.key == field ||
              entry.key.startsWith('$field.') ||
              entry.key.startsWith('$field['),
        )
        .map((entry) => entry.value)
        .toList(growable: false);
  }

  Widget _inlineErrors(BuildContext context, List<String> errors) {
    if (errors.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final error in errors)
            Text(
              error,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    );
  }

  Future<void> _showConflict() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Créneau indisponible'),
        content: const Text(
          'Ce créneau vient d’être complété. Choisissez-en un autre.',
        ),
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
    final cartState = _cart.state;
    final items = cartState.items
        .map(
          (item) => OrderItem(
            dishId: item.dish.id,
            name: item.dish.name,
            quantity: item.quantity,
            unitPrice: item.dish.priceInCents,
          ),
        )
        .toList(growable: false);
    final total = cartState.totalInCents;
    final menuId = cartState.items.isEmpty ? '' : cartState.items.first.menuId;
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        appBar: AppBar(title: const Text('Confirmer la commande')),
        body: BlocConsumer<OrdersBloc, OrdersState>(
          listener: (context, state) async {
            if (state is SlotConflict) {
              await _showConflict();
              if (context.mounted) {
                context.pushReplacement('/orders/checkout/slots');
              }
            } else if (state is OrderCreated) {
              _cart.clearCart();
              if (context.mounted) {
                context.go('/orders/${state.order.id}');
              }
            } else if (state is OrdersFailure) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.failure.message)));
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
                _inlineErrors(context, _fieldErrors(state, 'slotId')),
                const SizedBox(height: AppSpacing.m),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    child: Column(
                      children: [
                        for (final item in items)
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
                _inlineErrors(context, _fieldErrors(state, 'lines')),
                _inlineErrors(context, _fieldErrors(state, 'menuId')),
                const SizedBox(height: AppSpacing.l),
                SizedBox(
                  height: AppSpacing.buttonHeight,
                  child: FilledButton(
                    onPressed: isSubmitting || items.isEmpty || menuId.isEmpty
                        ? null
                        : () => _bloc.add(
                            CreateOrderRequested(
                              menuId: menuId,
                              timeSlotId: widget.slot.id,
                              items: items,
                            ),
                          ),
                    child: isSubmitting
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : Text(
                            state is OrdersFailure
                                ? 'Réessayer'
                                : 'Confirmer la commande',
                          ),
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
