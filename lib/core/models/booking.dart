class Booking {
  final String id;
  final String patientName;
  final String? patientPhone;
  final String doctorName;
  final String facilityName;
  final String status;
  final String? tokenNumber;
  final String? appointmentDate;
  final String? appointmentTime;
  final String? receiptUrl;

  Booking({
    required this.id,
    required this.patientName,
    this.patientPhone,
    required this.doctorName,
    required this.facilityName,
    required this.status,
    this.tokenNumber,
    this.appointmentDate,
    this.appointmentTime,
    this.receiptUrl,
  });

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: json['id'].toString(),
        patientName: json['patient_name'] ?? '',
        patientPhone: json['patient_phone'],
        doctorName: json['doctor_name'] ?? '',
        facilityName: json['facility_name'] ?? '',
        status: json['status'] ?? '',
        tokenNumber: json['token_number']?.toString(),
        appointmentDate: json['appointment_date'],
        appointmentTime: json['appointment_time'],
        receiptUrl: json['receipt_url'],
      );
}

class QueueToken {
  final String id;
  final String tokenNumber;
  final String patientName;
  final String status;

  QueueToken({
    required this.id,
    required this.tokenNumber,
    required this.patientName,
    required this.status,
  });

  factory QueueToken.fromJson(Map<String, dynamic> json) => QueueToken(
        id: json['id'].toString(),
        tokenNumber: json['token_number']?.toString() ?? '',
        patientName: json['patient_name'] ?? '',
        status: json['status'] ?? '',
      );
}

class LiveQueue {
  final QueueToken? current;
  final QueueToken? next;
  final int waitingCount;
  final bool isStalled;

  LiveQueue({
    this.current,
    this.next,
    this.waitingCount = 0,
    this.isStalled = false,
  });

  factory LiveQueue.fromJson(Map<String, dynamic> json) => LiveQueue(
        current: json['current'] != null
            ? QueueToken.fromJson(json['current'])
            : null,
        next: json['next'] != null ? QueueToken.fromJson(json['next']) : null,
        waitingCount: json['waiting_count'] ?? 0,
        isStalled: json['is_stalled'] ?? false,
      );
}
