import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core_providers.dart';
import '../models/ad.dart';

class NotificationsNotifier extends AsyncNotifier<List<AppNotification>> {
  @override
  Future<List<AppNotification>> build() => _fetch();

  Future<List<AppNotification>> _fetch() async {
    final api = ref.read(apiClientProvider);
    final res = await api.get('/api/v1/notifications/me');
    final list = (res.data as List).cast<Map<String, dynamic>>();
    return list.map(AppNotification.fromJson).toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> markRead(String id) async {
    final api = ref.read(apiClientProvider);
    await api.patch('/api/v1/notifications/$id/read');
    await refresh();
    ref.invalidate(unreadCountProvider);
  }

  Future<void> markAllRead() async {
    final api = ref.read(apiClientProvider);
    await api.post('/api/v1/notifications/read-all');
    await refresh();
    ref.invalidate(unreadCountProvider);
  }
}

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<AppNotification>>(
        NotificationsNotifier.new);

final unreadCountProvider = FutureProvider<int>((ref) async {
  final api = ref.read(apiClientProvider);
  final res = await api.get('/api/v1/notifications/me/unread-count');
  final data = res.data;
  if (data is Map) return (data['count'] ?? data['unread_count'] ?? 0) as int;
  return (data as num?)?.toInt() ?? 0;
});
