import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core_providers.dart';
import '../models/facility.dart';
import '../models/doctor.dart';

/// Loads the merchant's own facilities and keeps them cached in state.
class MyFacilitiesNotifier extends AsyncNotifier<List<Facility>> {
  @override
  Future<List<Facility>> build() => _fetch();

  Future<List<Facility>> _fetch() async {
    final api = ref.read(apiClientProvider);
    final res = await api.get('/api/v1/facilities/my');
    final list = (res.data as List).cast<Map<String, dynamic>>();
    return list.map(Facility.fromJson).toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<Facility> create({
    required String name,
    required String type,
    required String address,
    required String city,
    String? phone,
  }) async {
    final api = ref.read(apiClientProvider);
    final res = await api.post('/api/v1/facilities', data: {
      'name': name,
      'type': type,
      'address': address,
      'city': city,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
    });
    final created = Facility.fromJson(res.data);
    await refresh();
    return created;
  }

  Future<void> uploadPhoto(String facilityId, File file) async {
    final api = ref.read(apiClientProvider);
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
    });
    await api.postForm('/api/v1/facilities/$facilityId/photo', form);
    await refresh();
  }

  Future<void> editFacility(
    String facilityId, {
    String? name,
    String? address,
    String? city,
    String? phone,
  }) async {
    final api = ref.read(apiClientProvider);
    await api.patch('/api/v1/facilities/$facilityId', data: {
      if (name != null && name.isNotEmpty) 'name': name,
      if (address != null && address.isNotEmpty) 'address': address,
      if (city != null && city.isNotEmpty) 'city': city,
      if (phone != null) 'phone': phone.isEmpty ? null : phone,
    });
    await refresh();
  }

  Future<void> delete(String facilityId) async {
    final api = ref.read(apiClientProvider);
    await api.delete('/api/v1/facilities/$facilityId');
    await refresh();
  }
}

final myFacilitiesProvider =
    AsyncNotifierProvider<MyFacilitiesNotifier, List<Facility>>(
        MyFacilitiesNotifier.new);

final facilityDetailProvider =
    FutureProvider.family<Facility, String>((ref, id) async {
  final api = ref.read(apiClientProvider);
  final res = await api.get('/api/v1/facilities/$id');
  return Facility.fromJson(res.data);
});

/// Doctors for a given facility.
class FacilityDoctorsNotifier
    extends FamilyAsyncNotifier<List<Doctor>, String> {
  @override
  Future<List<Doctor>> build(String facilityId) => _fetch(facilityId);

  Future<List<Doctor>> _fetch(String facilityId) async {
    final api = ref.read(apiClientProvider);
    final res = await api.get('/api/v1/facilities/$facilityId/doctors');
    final list = (res.data as List).cast<Map<String, dynamic>>();
    return list.map(Doctor.fromJson).toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(arg));
  }

  Future<void> addDoctor({
    required String name,
    required String specialty,
    String? qualification,
    int? experienceYears,
    num? consultationFee,
  }) async {
    final api = ref.read(apiClientProvider);
    await api.post('/api/v1/facilities/$arg/doctors', data: {
      'name': name,
      'specialty': specialty,
      if (qualification != null) 'qualification': qualification,
      if (experienceYears != null) 'experience_years': experienceYears,
      if (consultationFee != null) 'consultation_fee': consultationFee,
    });
    await refresh();
  }

  Future<void> updateDoctor(
    String doctorId, {
    String? name,
    String? specialty,
    String? qualification,
    num? consultationFee,
  }) async {
    final api = ref.read(apiClientProvider);
    await api.patch('/api/v1/facilities/doctors/$doctorId', data: {
      if (name != null && name.isNotEmpty) 'full_name': name,
      if (specialty != null && specialty.isNotEmpty) 'specialty': specialty,
      if (qualification != null && qualification.isNotEmpty)
        'qualification': qualification,
      if (consultationFee != null) 'consultation_fee': consultationFee,
    });
    await refresh();
  }

  Future<void> uploadDoctorPhoto(String doctorId, File file) async {
    final api = ref.read(apiClientProvider);
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
    });
    await api.postForm('/api/v1/facilities/doctors/$doctorId/photo', form);
    await refresh();
  }
}

final facilityDoctorsProvider = AsyncNotifierProvider.family<
    FacilityDoctorsNotifier, List<Doctor>, String>(FacilityDoctorsNotifier.new);

/// Doctor's weekly availability + leave days.
class DoctorAvailabilityNotifier
    extends FamilyAsyncNotifier<List<DoctorSlot>, String> {
  @override
  Future<List<DoctorSlot>> build(String doctorId) => _fetch(doctorId);

  Future<List<DoctorSlot>> _fetch(String doctorId) async {
    final api = ref.read(apiClientProvider);
    final res = await api.get('/api/v1/facilities/doctors/$doctorId/availability');
    final list = (res.data as List).cast<Map<String, dynamic>>();
    return list.map(DoctorSlot.fromJson).toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(arg));
  }

  Future<void> addSlot({
    int? dayOfWeek,
    required String startTime,
    required String endTime,
    int slotDurationMinutes = 15,
    bool isLeave = false,
  }) async {
    final api = ref.read(apiClientProvider);
    await api.post('/api/v1/facilities/doctors/$arg/availability', data: {
      'day_of_week': isLeave ? null : dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'slot_duration_minutes': slotDurationMinutes,
      'is_leave': isLeave,
    });
    await refresh();
  }
}

final doctorAvailabilityProvider = AsyncNotifierProvider.family<
    DoctorAvailabilityNotifier, List<DoctorSlot>, String>(
    DoctorAvailabilityNotifier.new);
