import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:campus_eats_mobile/app/di/injection.dart';
import 'package:campus_eats_mobile/core/theme/app_spacing.dart';
import 'package:campus_eats_mobile/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:campus_eats_mobile/features/cart/presentation/cubit/cart_state.dart';
import 'package:campus_eats_mobile/features/menu/domain/dish.dart';
import 'package:campus_eats_mobile/features/menu/presentation/widgets/menu_formatters.dart';

class DishDetailArgs {
  const DishDetailArgs({
    required this.dish,
    required this.menuId,
    required this.date,
  });

  final Dish dish;
  final String menuId;
  final String date;
}

class DishDetailPage extends StatelessWidget {
  const DishDetailPage({super.key, required this.args});

  final DishDetailArgs args;

  @override
  Widget build(BuildContext context) {
    final dish = args.dish;
    final cartCubit = getIt<CartCubit>();
    final available = dish.isAvailable && dish.hasStock;
    return BlocProvider.value(
      value: cartCubit,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Détail du plat'),
          actions: [
            BlocBuilder<CartCubit, CartState>(
              builder: (context, state) => IconButton(
                tooltip: 'Ouvrir le panier',
                onPressed: () => context.push('/cart'),
                icon: Badge(
                  isLabelVisible: state.itemCount > 0,
                  label: Text('${state.itemCount}'),
                  child: const Icon(Icons.shopping_bag_outlined),
                ),
              ),
            ),
          ],
        ),
        body: BlocListener<CartCubit, CartState>(
          listenWhen: (_, current) => current.validationMessage != null,
          listener: (context, state) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.validationMessage!)));
          },
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.m),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusM),
                child: SizedBox(
                  height: 240,
                  child: dish.photoUrl == null || dish.photoUrl!.isEmpty
                      ? const ColoredBox(
                          color: Color(0xFFE0F2F1),
                          child: Icon(Icons.restaurant, size: 72),
                        )
                      : Image.network(
                          dish.photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const ColoredBox(
                            color: Color(0xFFE0F2F1),
                            child: Icon(Icons.restaurant, size: 72),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.l),
              Text(
                dish.name,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.s),
              Text(dish.description),
              const SizedBox(height: AppSpacing.m),
              Text(
                formatPrice(dish.priceInCents),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.m),
              Wrap(
                spacing: AppSpacing.s,
                runSpacing: AppSpacing.s,
                children: [
                  Chip(label: Text(_categoryLabel(dish.category))),
                  if (dish.isVegetarian) const Chip(label: Text('Végétarien')),
                ],
              ),
              if (dish.allergens.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.m),
                Text(
                  'Allergènes',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(dish.allergens.join(', ')),
              ],
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                height: AppSpacing.buttonHeight,
                child: FilledButton.icon(
                  onPressed: available
                      ? () {
                          cartCubit.addItem(
                            dish: dish,
                            menuId: args.menuId,
                            date: args.date,
                          );
                          if (cartCubit.state.validationMessage == null) {
                            context.pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${dish.name} ajouté au panier'),
                              ),
                            );
                          }
                        }
                      : null,
                  icon: const Icon(Icons.add_shopping_cart_rounded),
                  label: Text(
                    available ? 'Ajouter au panier' : 'Plat indisponible',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _categoryLabel(String category) => switch (category) {
    'entree' => 'Entrée',
    'plat' => 'Plat',
    'dessert' => 'Dessert',
    'boisson' => 'Boisson',
    _ => category,
  };
}
