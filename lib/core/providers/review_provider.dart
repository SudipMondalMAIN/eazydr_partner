import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core_providers.dart';
import '../models/ad.dart';

class ReviewTarget {
  final String kind; // 'facility' or 'doctor'
  final String id;
  const ReviewTarget(this.kind, this.id);

  @override
  bool operator ==(Object other) =>
      other is ReviewTarget && other.kind == kind && other.id == id;
  @override
  int get hashCode => Object.hash(kind, id);
}

final reviewsProvider =
    FutureProvider.family<List<Review>, ReviewTarget>((ref, target) async {
  final api = ref.read(apiClientProvider);
  final res = await api.get('/api/v1/reviews/${target.kind}/${target.id}');
  final list = (res.data as List).cast<Map<String, dynamic>>();
  return list.map(Review.fromJson).toList();
});

final reviewSummaryProvider =
    FutureProvider.family<ReviewSummary, ReviewTarget>((ref, target) async {
  final api = ref.read(apiClientProvider);
  final res =
      await api.get('/api/v1/reviews/${target.kind}/${target.id}/summary');
  return ReviewSummary.fromJson(Map<String, dynamic>.from(res.data));
});
