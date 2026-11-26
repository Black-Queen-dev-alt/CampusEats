import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:campus_eats_mobile/app/di/injection.dart';
import 'package:campus_eats_mobile/core/theme/app_spacing.dart';
import 'package:campus_eats_mobile/core/widgets/state_view.dart';
import 'package:campus_eats_mobile/features/cart/domain/cart_item.dart';
import 'package:campus_eats_mobile/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:campus_eats_mobile/features/cart/presentation/cubit/cart_state.dart';
import 'package:campus_eats_mobile/features/menu/presentation/widgets/menu_formatters.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = getIt<CartCubit>();
    return BlocProvider.value(
      value: cubit,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mon panier'),
          actions: [
            BlocBuilder<CartCubit, CartState>(
              builder: (context, state) => state.isEmpty
                  ? const SizedBox.shrink()
                  : TextButton(
                      onPressed: cubit.clearCart,
                      child: const Text('Vider'),
                    ),
            ),
          ],
        ),
        body: BlocConsumer<CartCubit, CartState>(
          listenWhen: (_, current) => current.validationMessage != null,
          listener: (context, state) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.validationMessage!)));
          },
          builder: (context, state) {
            if (state.isEmpty) {
              return StateView(
                isEmpty: true,
                emptyTitle: 'Votre panier est vide',
                emptyMessage: 'Ajoutez des plats depuis le menu du jour.',
                emptyActionLabel: 'Voir le menu',
                onEmptyAction: () => context.go('/menu'),
              );
            }
            final hasUnavailable = state.items.any((item) => !item.canFulfill);
            return Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    itemCount: state.items.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.s),
                    itemBuilder: (context, index) =>
                        _CartItemCard(item: state.items[index]),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    child: Column(
                      children: [
                        if (hasUnavailable)
                          const Padding(
                            padding: EdgeInsets.only(bottom: AppSpacing.s),
                            child: Text(
                              'Retirez les plats indisponibles avant de continuer.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ListTile(
                          title: const Text(
                            'Total',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          trailing: Text(
                            formatPrice(state.totalInCents),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          height: AppSpacing.buttonHeight,
                          child: FilledButton(
                            onPressed: hasUnavailable
                                ? null
                                : () => context.push('/orders/checkout/slots'),
                            child: const Text('Choisir un créneau'),
                          ),
                        ),
                      ],
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

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CartCubit>();
    final unavailable = !item.canFulfill;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.dish.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Retirer ${item.dish.name}',
                  onPressed: () => cubit.removeItem(item.dish.id),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
            Text(
              unavailable
                  ? 'Indisponible'
                  : formatPrice(item.dish.priceInCents),
            ),
            const SizedBox(height: AppSpacing.s),
            Row(
              children: [
                IconButton(
                  tooltip: 'Diminuer la quantité',
                  onPressed: () =>
                      cubit.changeQuantity(item.dish.id, item.quantity - 1),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text('${item.quantity}'),
                IconButton(
                  tooltip: 'Augmenter la quantité',
                  onPressed: unavailable
                      ? null
                      : () => cubit.changeQuantity(
                          item.dish.id,
                          item.quantity + 1,
                        ),
                  icon: const Icon(Icons.add_circle_outline),
                ),
                const Spacer(),
                Text(
                  formatPrice(item.subtotal),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
