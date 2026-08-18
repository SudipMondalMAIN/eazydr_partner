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
  /// image URL, per POST /ads/upload-image -> POST /ads.
  Future<void> createAd({
    required String title,
    required File image,
    String? facilityId,
  }) async {
    final api = ref.read(apiClientProvider);
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(image.path),
    });
    final uploadRes = await api.postForm('/api/v1/ads/upload-image', form);
    final imageUrl = uploadRes.data['image_url'] ?? uploadRes.data['url'];
    await api.post('/api/v1/ads', data: {
      'title': title,
      'image_url': imageUrl,
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
