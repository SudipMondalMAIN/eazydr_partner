import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core_providers.dart';
import '../models/ad.dart';

class MyAdsNotifier extends AsyncNotifier<List<Ad>> {
  @override
  Future<List<Ad>> build() => _fetch();

  Future<List<Ad>> _fetch() async {
    final api = ref.read(apiClientProvider);
    final res = await api.get('/api/v1/ads/mine');
    final list = (res.data as List).cast<Map<String, dynamic>>();
    return list.map(Ad.fromJson).toList();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  /// Uploads the creative first, then submits the ad using the returned
  /// storage key, per POST /ads/upload-image -> POST /ads. Backend's
  /// AdvertisementCreate requires image_storage_key (not image_url) and
  /// category — both were previously missing, which caused a 422 "Field
  /// required" error on every ad submission.
  Future<void> createAd({
    required String title,
    required File image,
    required String category,
    String? facilityId,
  }) async {
    final api = ref.read(apiClientProvider);
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(image.path),
    });
    final uploadRes = await api.postForm('/api/v1/ads/upload-image', form);
    final storageKey = uploadRes.data['storage_key'];
    await api.post('/api/v1/ads', data: {
      'title': title,
      'image_storage_key': storageKey,
      'category': category,
      if (facilityId != null) 'facility_id': facilityId,
    });
    await refresh();
  }
}

final myAdsProvider =
    AsyncNotifierProvider<MyAdsNotifier, List<Ad>>(MyAdsNotifier.new);

final publicBannersProvider = FutureProvider<List<AppBanner>>((ref) async {
  final api = ref.read(apiClientProvider);
  final res = await api.get('/api/v1/banners');
  final list = (res.data as List).cast<Map<String, dynamic>>();
  return list.map(AppBanner.fromJson).toList();
});
