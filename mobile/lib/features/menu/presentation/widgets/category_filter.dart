import 'package:flutter/material.dart';
import 'package:campus_eats_mobile/core/theme/app_spacing.dart';

class CategoryFilter extends StatelessWidget {
  const CategoryFilter({
    super.key,
    required this.selectedCategory,
    required this.onChanged,
  });

  final String? selectedCategory;
  final ValueChanged<String?> onChanged;

  static const _categories = <String, String>{
    'entree': 'Entrées',
    'plat': 'Plats',
    'dessert': 'Desserts',
    'boisson': 'Boissons',
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.buttonHeight,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.s),
            child: ChoiceChip(
              label: const Text('Tout'),
              selected: selectedCategory == null,
              onSelected: (_) => onChanged(null),
            ),
          ),
          for (final entry in _categories.entries)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.s),
              child: ChoiceChip(
                label: Text(entry.value),
                selected: selectedCategory == entry.key,
                onSelected: (_) => onChanged(entry.key),
              ),
            ),
        ],
      ),
    );
  }
}
