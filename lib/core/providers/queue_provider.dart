import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core_providers.dart';
import '../models/booking.dart';

final bookingDetailProvider =
    FutureProvider.family<Booking, String>((ref, id) async {
  final api = ref.read(apiClientProvider);
  final res = await api.get('/api/v1/bookings/$id');
  return Booking.fromJson(res.data);
});

final bookingReceiptProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final api = ref.read(apiClientProvider);
  final res = await api.get('/api/v1/bookings/$id/receipt');
  return Map<String, dynamic>.from(res.data);
});

class CheckInService {
  CheckInService(this.ref);
  final Ref ref;

  Future<Booking> checkInWithQr(String qrPayload) async {
    final api = ref.read(apiClientProvider);
    final res = await api
        .post('/api/v1/queue/check-in/qr', data: {'qr_data': qrPayload});
    return Booking.fromJson(res.data);
  }

  Future<Booking> checkInManual({String? bookingId, String? phone}) async {
    final api = ref.read(apiClientProvider);
    final res = await api.post('/api/v1/queue/check-in/manual', data: {
      if (bookingId != null && bookingId.isNotEmpty) 'booking_id': bookingId,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
    });
    return Booking.fromJson(res.data);
  }
}

final checkInServiceProvider = Provider((ref) => CheckInService(ref));

/// Polls the live queue for a doctor every 5 seconds, per the backend's
/// GET /queue/live/{doctor_id} contract (current/next token + stall flag).
class LiveQueueNotifier extends FamilyAsyncNotifier<LiveQueue, String> {
  Timer? _timer;

  @override
  Future<LiveQueue> build(String doctorId) async {
    ref.onDispose(() => _timer?.cancel());
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _poll(doctorId));
    return _fetch(doctorId);
  }

  Future<LiveQueue> _fetch(String doctorId) async {
    final api = ref.read(apiClientProvider);
    final res = await api.get('/api/v1/queue/live/$doctorId');
    return LiveQueue.fromJson(res.data);
  }

  Future<void> _poll(String doctorId) async {
    try {
      final data = await _fetch(doctorId);
      state = AsyncData(data);
    } catch (_) {
      // keep showing last known state on a transient poll failure
    }
  }

  Future<void> refreshNow() async {
    state = await AsyncValue.guard(() => _fetch(arg));
  }
}

final liveQueueProvider =
    AsyncNotifierProvider.family<LiveQueueNotifier, LiveQueue, String>(
        LiveQueueNotifier.new);
