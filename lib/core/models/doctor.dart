class Doctor {
  final String id;
  final String facilityId;
  final String name;
  final String specialty;
  final String? photoUrl;
  final String? qualification;
  final int? experienceYears;
  final num? consultationFee;

  Doctor({
    required this.id,
    required this.facilityId,
    required this.name,
    required this.specialty,
    this.photoUrl,
    this.qualification,
    this.experienceYears,
    this.consultationFee,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) => Doctor(
        id: json['id'].toString(),
        facilityId: (json['facility_id'] ?? '').toString(),
        name: json['name'] ?? json['full_name'] ?? '',
        specialty: json['specialty'] ?? json['specialization'] ?? '',
        photoUrl: json['photo_url'],
        qualification: json['qualification'],
        experienceYears: json['experience_years'],
        consultationFee: json['consultation_fee'],
      );
}

class DoctorSlot {
  final String id;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final int slotDurationMinutes;
  final bool isLeave;

  DoctorSlot({
    required this.id,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.slotDurationMinutes = 15,
    this.isLeave = false,
  });

  factory DoctorSlot.fromJson(Map<String, dynamic> json) => DoctorSlot(
        id: json['id'].toString(),
        dayOfWeek: json['day_of_week'] ?? json['date'] ?? '',
        startTime: json['start_time'] ?? '',
        endTime: json['end_time'] ?? '',
        slotDurationMinutes: json['slot_duration_minutes'] ?? 15,
        isLeave: json['is_leave'] ?? false,
      );
}
