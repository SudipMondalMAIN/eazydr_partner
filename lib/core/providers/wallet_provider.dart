import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core_providers.dart';
import '../models/withdrawal.dart';

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

  Future<void> request({
    required String facilityId,
    required num amount,
    String? note,
  }) async {
    state = const AsyncLoading();
    final api = ref.read(apiClientProvider);
    state = await AsyncValue.guard(() async {
      await api.post('/api/v1/rewards/withdrawals', data: {
        'facility_id': facilityId,
        'amount': amount,
        if (note != null && note.isNotEmpty) 'note': note,
      });
      ref.invalidate(rewardBalanceProvider);
      ref.invalidate(facilityEarningsProvider(facilityId));
      ref.invalidate(withdrawalHistoryProvider(facilityId));
    });
  }
}

final withdrawalProvider =
    AsyncNotifierProvider<WithdrawalNotifier, void>(WithdrawalNotifier.new);

/// History of withdrawal requests for one facility, most recent first.
class WithdrawalHistoryNotifier
    extends FamilyAsyncNotifier<List<Withdrawal>, String> {
  @override
  Future<List<Withdrawal>> build(String facilityId) => _fetch(facilityId);

  Future<List<Withdrawal>> _fetch(String facilityId) async {
    final api = ref.read(apiClientProvider);
    final res = await api.get('/api/v1/rewards/withdrawals/$facilityId');
    final list = (res.data as List).cast<Map<String, dynamic>>();
    return list.map(Withdrawal.fromJson).toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(arg));
  }
}

final withdrawalHistoryProvider = AsyncNotifierProvider.family<
    WithdrawalHistoryNotifier, List<Withdrawal>, String>(
    WithdrawalHistoryNotifier.new);
