import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core_providers.dart';

final facilityEarningsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, facilityId) async {
  final api = ref.read(apiClientProvider);
  final res = await api.get('/api/v1/rewards/earnings/$facilityId');
  return Map<String, dynamic>.from(res.data);
});

final rewardBalanceProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.read(apiClientProvider);
  final res = await api.get('/api/v1/rewards/balance');
  return Map<String, dynamic>.from(res.data);
});

class WithdrawalNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> request({required num amount, String? note}) async {
    state = const AsyncLoading();
    final api = ref.read(apiClientProvider);
    state = await AsyncValue.guard(() async {
      await api.post('/api/v1/rewards/withdrawals', data: {
        'amount': amount,
        if (note != null && note.isNotEmpty) 'note': note,
      });
      ref.invalidate(rewardBalanceProvider);
    });
  }
}

final withdrawalProvider =
    AsyncNotifierProvider<WithdrawalNotifier, void>(WithdrawalNotifier.new);
