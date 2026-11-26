import 'package:flutter/material.dart';
import 'package:campus_eats_mobile/core/theme/app_spacing.dart';

import 'menu_formatters.dart';

class DaySelector extends StatelessWidget {
  const DaySelector({
    super.key,
    required this.selectedDate,
    required this.onSelected,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelected;

  static const _weekdays = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime.now();
    final days = List.generate(
      7,
      (index) => DateTime(firstDay.year, firstDay.month, firstDay.day + index),
    );
    return SizedBox(
      height: 82,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.m,
          vertical: AppSpacing.s,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.s),
        itemBuilder: (context, index) {
          final day = days[index];
          final selected = formatMenuDate(day) == formatMenuDate(selectedDate);
          return Semantics(
            button: true,
            selected: selected,
            label: '${_weekdays[day.weekday - 1]} ${day.day}',
            child: ChoiceChip(
              selected: selected,
              onSelected: (_) => onSelected(day),
              label: SizedBox(
                width: 48,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_weekdays[day.weekday - 1]),
                    Text(
                      '${day.day}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
