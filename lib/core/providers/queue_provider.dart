import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_exception.dart';
import '../core_providers.dart';
import '../models/booking.dart';

/// Fetches full booking details via the /receipt endpoint, which returns
/// everything the plain /bookings/{id} endpoint does plus doctor/facility
/// display names and the QR image — one call covers the whole detail
/// screen instead of two mismatched ones.
final bookingDetailProvider =
    FutureProvider.family<Booking, String>((ref, id) async {
  final api = ref.read(apiClientProvider);
  final res = await api.get('/api/v1/bookings/$id/receipt');
  return Booking.fromJson(res.data);
});

class CheckInService {
  CheckInService(this.ref);
  final Ref ref;

  /// Parses the scanned QR payload, which is a URI in the form
  /// `eazydoctor://checkin?uuid=<qr_uuid>&sig=<signature>`, and posts the
  /// two fields separately as the backend's QrCheckInRequest expects.
  Future<CheckInResult> checkInWithQr(String rawQrPayload) async {
    final uri = Uri.tryParse(rawQrPayload);
    final qrUuid = uri?.queryParameters['uuid'];
    final signature = uri?.queryParameters['sig'];
    if (qrUuid == null || signature == null) {
      throw ApiException('Unrecognized QR code');
    }
    final api = ref.read(apiClientProvider);
    final res = await api.post('/api/v1/queue/check-in/qr',
        data: {'qr_uuid': qrUuid, 'signature': signature});
    return CheckInResult.fromJson(res.data);
  }

  Future<CheckInResult> checkInManual({
    required String doctorId,
    required String appointmentDate,
    String? bookingId,
    String? patientPhone,
  }) async {
    final api = ref.read(apiClientProvider);
    final res = await api.post('/api/v1/queue/check-in/manual', data: {
      'doctor_id': doctorId,
      'appointment_date': appointmentDate,
      if (bookingId != null && bookingId.isNotEmpty) 'booking_id': bookingId,
      if (patientPhone != null && patientPhone.isNotEmpty)
        'patient_phone': patientPhone,
    });
    return CheckInResult.fromJson(res.data);
  }

  Future<ConsultationResult> startConsultation(String bookingId) async {
    final api = ref.read(apiClientProvider);
    final res =
        await api.post('/api/v1/queue/consultation/$bookingId/start');
    return ConsultationResult.fromJson(res.data);
  }

  Future<ConsultationResult> completeConsultation(String bookingId) async {
    final api = ref.read(apiClientProvider);
    final res =
        await api.post('/api/v1/queue/consultation/$bookingId/complete');
    return ConsultationResult.fromJson(res.data);
  }
}

final checkInServiceProvider = Provider((ref) => CheckInService(ref));

/// Polls the live queue for a doctor every 5 seconds, per the backend's
/// GET /queue/live/{doctor_id} contract (today's current token + stall
/// flag only — no "next" token or waiting count is exposed).
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
