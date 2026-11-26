import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:campus_eats_mobile/app/di/injection.dart';
import 'package:campus_eats_mobile/core/theme/app_spacing.dart';
import 'package:campus_eats_mobile/core/widgets/state_view.dart';
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
  TimeSlot? _selected;

  @override
  void initState() {
    super.initState();
    _bloc = getIt<TimeSlotsBloc>()..add(TimeSlotsRequested(_today()));
  }

  String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        appBar: AppBar(title: const Text('Choisir un créneau')),
        body: BlocBuilder<TimeSlotsBloc, TimeSlotsState>(
          builder: (context, state) {
            final isLoading = state is TimeSlotsLoading;
            final failure = state is TimeSlotsFailure ? state.failure : null;
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
                onRetry: () => _bloc.add(SlotRefreshRequested(_today())),
                emptyTitle: 'Aucun créneau disponible',
                emptyMessage: 'Aucun créneau n’est publié pour cette date.',
                emptyActionLabel: 'Actualiser',
                onEmptyAction: () => _bloc.add(SlotRefreshRequested(_today())),
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
                                  ? Theme.of(context)
                                        .colorScheme
                                        .primaryContainer
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
                                      : '${slot.remaining} place${slot.remaining > 1 ? 's' : ''} restante${slot.remaining > 1 ? 's' : ''}',
                                ),
                                trailing: selected
                                    ? const Icon(Icons.check_circle)
                                    : null,
                                onTap: slot.isFull
                                    ? null
                                    : () => setState(() => _selected = slot),
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
                        child: const Text('Continuer vers la confirmation'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
