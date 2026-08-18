import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/wallet_provider.dart';

class WithdrawalHistoryScreen extends ConsumerWidget {
  final String facilityId;
  const WithdrawalHistoryScreen({super.key, required this.facilityId});

  Color _statusColor(String status) {
    switch (status) {
      case 'success':
        return Colors.green;
      case 'failed':
        return Colors.red;
      case 'processing':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(withdrawalHistoryProvider(facilityId));

    return Scaffold(
      appBar: AppBar(title: const Text('Withdrawal History')),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(withdrawalHistoryProvider(facilityId).notifier).refresh(),
        child: history.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(children: [
            const SizedBox(height: 80),
            Center(child: Text('Failed to load: $e')),
          ]),
          data: (list) {
            if (list.isEmpty) {
              return ListView(children: const [
                SizedBox(height: 100),
                Center(child: Text('No withdrawal requests yet.')),
              ]);
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final w = list[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    title: Text('₹${w.amount}'),
                    subtitle: Text(
                      [
                        w.createdAt,
                        if (w.failureReason != null) w.failureReason!,
                      ].join(' · '),
                    ),
                    trailing: Chip(
                      label: Text(w.status),
                      backgroundColor:
                          _statusColor(w.status).withValues(alpha: 0.15),
                      labelStyle: TextStyle(color: _statusColor(w.status)),
                    ),
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
