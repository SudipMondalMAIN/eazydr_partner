import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/review_provider.dart';

class ReviewListScreen extends ConsumerWidget {
  final ReviewTarget target;
  final String title;
  const ReviewListScreen({super.key, required this.target, required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(reviewSummaryProvider(target));
    final reviews = ref.watch(reviewsProvider(target));

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          summary.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => const SizedBox.shrink(),
            data: (s) => Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Icon(Icons.star_rounded,
                        color: Colors.amber[700], size: 36),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.average.toStringAsFixed(1),
                            style: Theme.of(context).textTheme.headlineMedium),
                        Text('${s.total} reviews',
                            style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          reviews.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Failed to load reviews: $e'),
            data: (list) {
              if (list.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(child: Text('No reviews yet.')),
                );
              }
              return Column(
                children: list
                    .map((r) => Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            title: Text(r.reviewerName),
                            subtitle: r.comment != null
                                ? Text(r.comment!)
                                : null,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded,
                                    color: Colors.amber, size: 18),
                                Text(r.rating.toStringAsFixed(1)),
                              ],
                            ),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
