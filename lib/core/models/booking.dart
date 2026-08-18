/// Matches backend's BookingWithQrOut (GET /bookings/{id}/receipt), which
/// is a superset of BookingOut (GET /bookings/{id}) plus doctor/facility
/// display names and the QR image — so the app always fetches via the
/// /receipt endpoint to get everything in one call.
class Booking {
  final String id;
  final String bookingCode;
  final String patientName;
  final String? patientPhone;
  final String doctorName;
  final String facilityName;
  final String facilityAddress;
  final String status;
  final String tokenNumber;
  final String appointmentDate;
  final String expectedTime;
  final String? qrCodeBase64;

  Booking({
    required this.id,
    required this.bookingCode,
    required this.patientName,
    this.patientPhone,
    required this.doctorName,
    required this.facilityName,
    required this.facilityAddress,
    required this.status,
    required this.tokenNumber,
    required this.appointmentDate,
    required this.expectedTime,
    this.qrCodeBase64,
  });

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: (json['id'] ?? json['booking_id']).toString(),
        bookingCode: json['booking_code'] ?? '',
        patientName: json['patient_name'] ?? '',
        patientPhone: json['patient_phone'],
        doctorName: json['doctor_name'] ?? '',
        facilityName: json['facility_name'] ?? '',
        facilityAddress: json['facility_address'] ?? '',
        status: json['status'] ?? '',
        tokenNumber: json['token_number']?.toString() ?? '',
        appointmentDate: json['appointment_date'] ?? '',
        expectedTime: json['expected_time'] ?? '',
        qrCodeBase64: json['qr_code_base64'],
      );
}

/// Response of POST /queue/check-in/qr and /queue/check-in/manual
/// (backend's CheckInResult schema) — deliberately separate from [Booking]
/// since the shape differs (uses booking_id, no facility/doctor names).
class CheckInResult {
  final String bookingId;
  final String patientName;
  final String doctorId;
  final int tokenNumber;
  final String status;
  final String checkedInAt;

  CheckInResult({
    required this.bookingId,
    required this.patientName,
    required this.doctorId,
    required this.tokenNumber,
    required this.status,
    required this.checkedInAt,
  });

  factory CheckInResult.fromJson(Map<String, dynamic> json) => CheckInResult(
        bookingId: json['booking_id'].toString(),
        patientName: json['patient_name'] ?? '',
        doctorId: json['doctor_id'].toString(),
        tokenNumber: json['token_number'] ?? 0,
        status: json['status'] ?? '',
        checkedInAt: json['checked_in_at'] ?? '',
      );
}

/// Matches backend's LiveQueueOut (GET /queue/live/{doctor_id}): only a
/// single "now serving" token number for the day, plus a stall flag. The
/// backend does not expose a "next" token, waiting count, or patient
/// names for this endpoint.
class LiveQueue {
  final String doctorId;
  final String queueDate;
  final int currentToken;
  final bool isStalled;

  LiveQueue({
    required this.doctorId,
    required this.queueDate,
    required this.currentToken,
    required this.isStalled,
  });

  factory LiveQueue.fromJson(Map<String, dynamic> json) => LiveQueue(
        doctorId: (json['doctor_id'] ?? '').toString(),
        queueDate: json['queue_date'] ?? '',
        currentToken: json['current_token'] ?? 0,
        isStalled: json['is_stalled'] ?? false,
      );
}
