import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:campus_eats_mobile/app/di/injection.dart';
import 'package:campus_eats_mobile/core/theme/app_spacing.dart';
import 'package:campus_eats_mobile/core/widgets/state_view.dart';
import 'package:campus_eats_mobile/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:campus_eats_mobile/features/time_slots/domain/time_slot.dart';
import 'package:campus_eats_mobile/features/time_slots/presentation/bloc/time_slots_bloc.dart';
import 'package:campus_eats_mobile/features/time_slots/presentation/bloc/time_slots_event.dart';
import 'package:campus_eats_mobile/features/time_slots/presentation/bloc/time_slots_state.dart';

class SlotPickerPage extends StatefulWidget {
  const SlotPickerPage({super.key});

  @override
  State<SlotPickerPage> createState() => _SlotPickerPageState();
}

class _SlotPickerPageState extends State<SlotPickerPage> {
  late final TimeSlotsBloc _bloc;
  late final CartCubit _cart;
  late DateTime _selectedDate;
  TimeSlot? _selected;

  @override
  void initState() {
    super.initState();
    _bloc = getIt<TimeSlotsBloc>();
    _cart = getIt<CartCubit>();
    final cartDate = _cart.state.items.isEmpty
        ? null
        : DateTime.tryParse(_cart.state.items.first.date);
    _selectedDate = cartDate ?? DateTime.now();
    _loadSlots();
  }

  String _dateParam(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  String _dateLabel(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  void _loadSlots() {
    _bloc.add(TimeSlotsRequested(_dateParam(_selectedDate)));
  }

  Future<void> _selectDate() async {
    final today = DateTime.now();
    final firstDate = DateTime(today.year, today.month, today.day);
    final lastDate = DateTime(today.year + 1, today.month, today.day);
    final initialDate = _selectedDate.isBefore(firstDate)
        ? firstDate
        : _selectedDate.isAfter(lastDate)
        ? lastDate
        : _selectedDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (!mounted ||
        picked == null ||
        _dateParam(picked) == _dateParam(_selectedDate)) {
      return;
    }

    if (_cart.state.items.isNotEmpty) {
      final clearCart = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Changer la date du panier ?'),
          content: const Text(
            'Votre panier est lié à une autre date. Le vider pour choisir '
            'un créneau à cette nouvelle date ?',
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(false),
              child: const Text('Garder mon panier'),
            ),
            FilledButton(
              onPressed: () => context.pop(true),
              child: const Text('Vider et continuer'),
            ),
          ],
        ),
      );
      if (clearCart != true || !mounted) return;
      _cart.clearCart();
    }

    setState(() {
      _selectedDate = picked;
      _selected = null;
    });
    _loadSlots();
  }

  @override
  void dispose() {
    unawaited(_bloc.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        appBar: AppBar(title: const Text('Choisir un créneau')),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.m,
                AppSpacing.s,
                AppSpacing.m,
                0,
              ),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _selectDate,
                  icon: const Icon(Icons.calendar_today_rounded),
                  label: Text('Date : ${_dateLabel(_selectedDate)}'),
                ),
              ),
            ),
            Expanded(
              child: BlocBuilder<TimeSlotsBloc, TimeSlotsState>(
                builder: (context, state) {
                  final isLoading = state is TimeSlotsLoading;
                  final failure = state is TimeSlotsFailure
                      ? state.failure
                      : null;
                  final isEmpty = state is TimeSlotsEmpty;
                  final slots = state is TimeSlotsLoaded
                      ? state.slots
                      : const <TimeSlot>[];
                  return Padding(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    child: StateView(
                      isLoading: isLoading,
                      isEmpty: isEmpty,
                      failure: failure,
                      onRetry: () => _bloc.add(
                        SlotRefreshRequested(_dateParam(_selectedDate)),
                      ),
                      emptyTitle: 'Aucun créneau disponible',
                      emptyMessage:
                          'Aucun créneau n’est publié pour cette date.',
                      emptyActionLabel: 'Actualiser',
                      onEmptyAction: () => _bloc.add(
                        SlotRefreshRequested(_dateParam(_selectedDate)),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: ListView.separated(
                              itemCount: slots.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: AppSpacing.s),
                              itemBuilder: (context, index) {
                                final slot = slots[index];
                                final selected = _selected?.id == slot.id;
                                return Semantics(
                                  selected: selected,
                                  child: Card(
                                    color: selected
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.primaryContainer
                                        : null,
                                    child: ListTile(
                                      enabled: !slot.isFull,
                                      contentPadding: const EdgeInsets.all(
                                        AppSpacing.m,
                                      ),
                                      leading: const Icon(
                                        Icons.schedule_rounded,
                                        size: 32,
                                      ),
                                      title: Text(
                                        '${slot.startTime} - ${slot.endTime}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      subtitle: Text(
                                        slot.isFull
                                            ? 'Complet'
                                            : slot.remainingPlaces == null
                                            ? 'Disponible'
                                            : '${slot.remaining} place${slot.remaining > 1 ? 's' : ''} restante${slot.remaining > 1 ? 's' : ''}',
                                      ),
                                      trailing: selected
                                          ? const Icon(Icons.check_circle)
                                          : null,
                                      onTap: slot.isFull
                                          ? null
                                          : () => setState(
                                              () => _selected = slot,
                                            ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: AppSpacing.m),
                          SizedBox(
                            width: double.infinity,
                            height: AppSpacing.buttonHeight,
                            child: FilledButton(
                              onPressed: _selected == null
                                  ? null
                                  : () => context.push(
                                      '/orders/checkout',
                                      extra: _selected,
                                    ),
                              child: const Text(
                                'Continuer vers la confirmation',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
