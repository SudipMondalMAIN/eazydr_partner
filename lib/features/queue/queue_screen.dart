import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/facility_provider.dart';
import '../../core/providers/queue_provider.dart';

class QueueScreen extends ConsumerStatefulWidget {
  const QueueScreen({super.key});

  @override
  ConsumerState<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends ConsumerState<QueueScreen> {
  String? _facilityId;
  String? _doctorId;

  @override
  Widget build(BuildContext context) {
    final facilities = ref.watch(myFacilitiesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Live Queue')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            facilities.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Failed to load facilities: $e'),
              data: (list) {
                if (list.isEmpty) return const Text('Add a facility first.');
                _facilityId ??= list.first.id;
                return DropdownButtonFormField<String>(
                  initialValue: _facilityId,
                  decoration: const InputDecoration(labelText: 'Facility'),
                  items: list
                      .map((f) =>
                          DropdownMenuItem(value: f.id, child: Text(f.name)))
                      .toList(),
                  onChanged: (v) => setState(() {
                    _facilityId = v;
                    _doctorId = null;
                  }),
                );
              },
            ),
            const SizedBox(height: 12),
            if (_facilityId != null)
              Consumer(builder: (context, ref, _) {
                final doctors =
                    ref.watch(facilityDoctorsProvider(_facilityId!));
                return doctors.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Failed to load doctors: $e'),
                  data: (list) {
                    if (list.isEmpty) {
                      return const Text('No doctors under this facility.');
                    }
                    _doctorId ??= list.first.id;
                    return DropdownButtonFormField<String>(
                      initialValue: _doctorId,
                      decoration: const InputDecoration(labelText: 'Doctor'),
                      items: list
                          .map((d) => DropdownMenuItem(
                              value: d.id, child: Text(d.name)))
                          .toList(),
                      onChanged: (v) => setState(() => _doctorId = v),
                    );
                  },
                );
              }),
            const SizedBox(height: 20),
            if (_doctorId != null)
              Expanded(child: _LiveQueueView(doctorId: _doctorId!)),
          ],
        ),
      ),
    );
  }
}

class _LiveQueueView extends ConsumerWidget {
  final String doctorId;
  const _LiveQueueView({required this.doctorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(liveQueueProvider(doctorId));

    return queue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Failed to load queue: $e')),
      data: (q) {
        return RefreshIndicator(
          onRefresh: () =>
              ref.read(liveQueueProvider(doctorId).notifier).refreshNow(),
          child: ListView(
            children: [
              if (q.isStalled)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange),
                      SizedBox(width: 10),
                      Expanded(
                          child: Text(
                              'Queue seems stalled — no token called recently.')),
                    ],
                  ),
                ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text('Now serving',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(
                        q.currentToken > 0 ? '${q.currentToken}' : '—',
                        style: Theme.of(context)
                            .textTheme
                            .displayLarge
                            ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(q.queueDate,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
