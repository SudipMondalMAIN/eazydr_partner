import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/facility_provider.dart';

class DoctorAvailabilityScreen extends ConsumerStatefulWidget {
  final String doctorId;
  final String doctorName;
  const DoctorAvailabilityScreen(
      {super.key, required this.doctorId, required this.doctorName});

  @override
  ConsumerState<DoctorAvailabilityScreen> createState() =>
      _DoctorAvailabilityScreenState();
}

class _DoctorAvailabilityScreenState
    extends ConsumerState<DoctorAvailabilityScreen> {
  static const _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  Future<void> _openAddSlotSheet({bool isLeave = false}) async {
    String day = _days.first;
    TimeOfDay start = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay end = const TimeOfDay(hour: 13, minute: 0);
    final durationCtrl = TextEditingController(text: '15');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(isLeave ? 'Mark leave day' : 'Add availability',
                  style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: day,
                decoration: const InputDecoration(labelText: 'Day'),
                items: _days
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (v) => setSheetState(() => day = v ?? day),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final picked = await showTimePicker(
                            context: ctx, initialTime: start);
                        if (picked != null) {
                          setSheetState(() => start = picked);
                        }
                      },
                      child: Text('Start: ${start.format(ctx)}'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final picked =
                            await showTimePicker(context: ctx, initialTime: end);
                        if (picked != null) setSheetState(() => end = picked);
                      },
                      child: Text('End: ${end.format(ctx)}'),
                    ),
                  ),
                ],
              ),
              if (!isLeave) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: durationCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Slot duration (minutes)'),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () async {
                  String fmt(TimeOfDay t) =>
                      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                  await ref
                      .read(doctorAvailabilityProvider(widget.doctorId)
                          .notifier)
                      .addSlot(
                        dayOfWeek: day,
                        startTime: fmt(start),
                        endTime: fmt(end),
                        slotDurationMinutes:
                            int.tryParse(durationCtrl.text.trim()) ?? 15,
                        isLeave: isLeave,
                      );
                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final slots = ref.watch(doctorAvailabilityProvider(widget.doctorId));

    return Scaffold(
      appBar: AppBar(title: Text('${widget.doctorName} · Schedule')),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'leave',
            onPressed: () => _openAddSlotSheet(isLeave: true),
            icon: const Icon(Icons.event_busy_rounded),
            label: const Text('Leave day'),
            backgroundColor: Colors.orange,
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'slot',
            onPressed: () => _openAddSlotSheet(),
            icon: const Icon(Icons.add),
            label: const Text('Add slot'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(doctorAvailabilityProvider(widget.doctorId).notifier).refresh(),
        child: slots.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(children: [
            const SizedBox(height: 80),
            Center(child: Text('Failed to load: $e')),
          ]),
          data: (list) {
            if (list.isEmpty) {
              return ListView(children: const [
                SizedBox(height: 100),
                Center(child: Text('No schedule set yet.')),
              ]);
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 140),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final s = list[i];
                return Card(
                  color: s.isLeave
                      ? Colors.orange.withValues(alpha: 0.12)
                      : null,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: Icon(s.isLeave
                        ? Icons.event_busy_rounded
                        : Icons.schedule_rounded),
                    title: Text(s.dayOfWeek),
                    subtitle: Text(s.isLeave
                        ? 'On leave'
                        : '${s.startTime} – ${s.endTime} · ${s.slotDurationMinutes} min slots'),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
