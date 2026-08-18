import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/core_providers.dart';
import '../../core/models/facility.dart';

/// Facilities owned by the logged-in merchant.
class FacilitiesNotifier extends AsyncNotifier<List<Facility>> {
  @override
  Future<List<Facility>> build() async {
    final api = ref.read(apiClientProvider);
    final res = await api.get('/api/v1/facilities/my');
    return (res.data as List).map((e) => Facility.fromJson(e)).toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final api = ref.read(apiClientProvider);
      final res = await api.get('/api/v1/facilities/my');
      return (res.data as List).map((e) => Facility.fromJson(e)).toList();
    });
  }

  Future<Facility> createFacility({
    required String name,
    required String facilityType,
    required String address,
    required String city,
    required double latitude,
    required double longitude,
    required double bookingFee,
    String? phone,
    String? email,
    String? description,
    String? workingHours,
  }) async {
    final api = ref.read(apiClientProvider);
    final res = await api.post('/api/v1/facilities', data: {
      'name': name,
      'facility_type': facilityType,
      'address': address,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'booking_fee': bookingFee,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (email != null && email.isNotEmpty) 'email': email,
      if (description != null && description.isNotEmpty) 'description': description,
      if (workingHours != null && workingHours.isNotEmpty) 'working_hours': workingHours,
    });
    final facility = Facility.fromJson(res.data);
    await refresh();
    return facility;
  }

  /// Patch-style edit — only send fields that changed. facility_type,
  /// booking_fee and photo are NOT editable via this endpoint (backend
  /// FacilityUpdate doesn't accept them); photo has its own upload call.
  Future<Facility> updateFacility(
    String facilityId, {
    String? name,
    String? address,
    String? city,
    String? state,
    String? phone,
    String? email,
    String? description,
    String? workingHours,
    double? latitude,
    double? longitude,
  }) async {
    final api = ref.read(apiClientProvider);
    final res = await api.patch('/api/v1/facilities/$facilityId', data: {
      if (name != null) 'name': name,
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (description != null) 'description': description,
      if (workingHours != null) 'working_hours': workingHours,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    });
    final facility = Facility.fromJson(res.data);
    await refresh();
    return facility;
  }

  Future<Facility> uploadFacilityPhoto(String facilityId, String filePath) async {
    final api = ref.read(apiClientProvider);
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final res = await api.postForm('/api/v1/facilities/$facilityId/photo', form);
    final facility = Facility.fromJson(res.data);
    await refresh();
    return facility;
  }

  /// Soft-delete — facility disappears from this list and patient search;
  /// its doctors/bookings/earnings history are kept intact server-side.
  Future<void> deleteFacility(String facilityId) async {
    final api = ref.read(apiClientProvider);
    await api.delete('/api/v1/facilities/$facilityId');
    await refresh();
  }
}

final facilitiesProvider = AsyncNotifierProvider<FacilitiesNotifier, List<Facility>>(FacilitiesNotifier.new);

/// Doctors for a given facility.
class DoctorsNotifier extends FamilyAsyncNotifier<List<Doctor>, String> {
  @override
  Future<List<Doctor>> build(String facilityId) async {
    final api = ref.read(apiClientProvider);
    final res = await api.get('/api/v1/facilities/$facilityId/doctors');
    return (res.data as List).map((e) => Doctor.fromJson(e)).toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final api = ref.read(apiClientProvider);
      final res = await api.get('/api/v1/facilities/$arg/doctors');
      return (res.data as List).map((e) => Doctor.fromJson(e)).toList();
    });
  }

  Future<void> addDoctor({
    required String fullName,
    required String qualification,
    required String specialty,
    required double consultationFee,
  }) async {
    final api = ref.read(apiClientProvider);
    await api.post('/api/v1/facilities/$arg/doctors', data: {
      'full_name': fullName,
      'qualification': qualification,
      'specialty': specialty,
      'consultation_fee': consultationFee,
    });
    await refresh();
  }

  Future<Doctor> uploadDoctorPhoto(String doctorId, String filePath) async {
    final api = ref.read(apiClientProvider);
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final res = await api.postForm('/api/v1/facilities/doctors/$doctorId/photo', form);
    final doctor = Doctor.fromJson(res.data);
    await refresh();
    return doctor;
  }
}

final doctorsProvider =
    AsyncNotifierProvider.family<DoctorsNotifier, List<Doctor>, String>(DoctorsNotifier.new);
