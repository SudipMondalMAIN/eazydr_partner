import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/facility_provider.dart';
import '../../core/providers/wallet_provider.dart';
import 'withdrawal_history_screen.dart';

class EarningsScreen extends ConsumerStatefulWidget {
  const EarningsScreen({super.key});

  @override
  ConsumerState<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends ConsumerState<EarningsScreen> {
  String? _facilityId;

  Future<void> _openWithdrawSheet(String facilityId, num maxAmount) async {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Request withdrawal',
                style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 16),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
            ),
            const SizedBox(height: 20),
            Consumer(builder: (context, ref, _) {
              final w = ref.watch(withdrawalProvider);
              return FilledButton(
                onPressed: w.isLoading
                    ? null
                    : () async {
                        final amount = num.tryParse(amountCtrl.text.trim());
                        if (amount == null || amount <= 0) return;
                        await ref.read(withdrawalProvider.notifier).request(
                            facilityId: facilityId,
                            amount: amount,
                            note: noteCtrl.text.trim());
                        if (ctx.mounted) Navigator.of(ctx).pop();
                      },
                child: w.isLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Submit request'),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final facilities = ref.watch(myFacilitiesProvider);
    final rewardBalance = ref.watch(rewardBalanceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Earnings')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(rewardBalanceProvider);
          if (_facilityId != null) {
            ref.invalidate(facilityEarningsProvider(_facilityId!));
          }
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            rewardBalance.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Failed to load reward balance: $e'),
              data: (data) {
                final points = data['points'] ?? data['balance'] ?? 0;
                return Card(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.08),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Reward points',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                        Text('$points',
                            style: Theme.of(context).textTheme.headlineSmall),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Text('Facility earnings',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            facilities.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Failed to load facilities: $e'),
              data: (list) {
                if (list.isEmpty) return const Text('No facilities yet.');
                _facilityId ??= list.first.id;
                return Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _facilityId,
                      decoration:
                          const InputDecoration(labelText: 'Facility'),
                      items: list
                          .map((f) => DropdownMenuItem(
                              value: f.id, child: Text(f.name)))
                          .toList(),
                      onChanged: (v) => setState(() => _facilityId = v),
                    ),
                    const SizedBox(height: 14),
                    if (_facilityId != null)
                      Consumer(builder: (context, ref, _) {
                        final earnings =
                            ref.watch(facilityEarningsProvider(_facilityId!));
                        return earnings.when(
                          loading: () => const LinearProgressIndicator(),
                          error: (e, _) => Text('Failed to load: $e'),
                          data: (data) {
                            final balance =
                                data['balance'] ?? data['total_earnings'] ?? 0;
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text('Wallet balance',
                                        style: TextStyle(color: Colors.grey)),
                                    const SizedBox(height: 6),
                                    Text('₹$balance',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium),
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: FilledButton.icon(
                                            onPressed: () => _openWithdrawSheet(
                                                _facilityId!,
                                                (balance is num) ? balance : 0),
                                            icon: const Icon(Icons
                                                .account_balance_wallet_rounded),
                                            label:
                                                const Text('Request withdrawal'),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        OutlinedButton.icon(
                                          onPressed: () => Navigator.of(context)
                                              .push(MaterialPageRoute(
                                                  builder: (_) =>
                                                      WithdrawalHistoryScreen(
                                                          facilityId:
                                                              _facilityId!))),
                                          icon: const Icon(Icons.history_rounded),
                                          label: const Text('History'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
