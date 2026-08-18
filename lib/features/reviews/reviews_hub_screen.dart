import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/facility_provider.dart';
import '../../core/providers/review_provider.dart';
import 'review_list_screen.dart';

class ReviewsHubScreen extends ConsumerWidget {
  const ReviewsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facilities = ref.watch(myFacilitiesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Reviews & Ratings')),
      body: facilities.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('No facilities yet.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final f = list[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text(f.name),
                  subtitle: Text(f.city),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ReviewListScreen(
                          target: ReviewTarget('facility', f.id),
                          title: f.name))),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
