import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/ads_provider.dart';
import 'ad_form_screen.dart';

class AdsScreen extends ConsumerWidget {
  const AdsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ads = ref.watch(myAdsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sponsored Ads')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const AdFormScreen()));
          ref.read(myAdsProvider.notifier).refresh();
        },
        icon: const Icon(Icons.add),
        label: const Text('New ad'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(myAdsProvider.notifier).refresh(),
        child: ads.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(children: [
            const SizedBox(height: 80),
            Center(child: Text('Failed to load: $e')),
          ]),
          data: (list) {
            if (list.isEmpty) {
              return ListView(children: const [
                SizedBox(height: 100),
                Center(child: Text('No ads submitted yet.')),
              ]);
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final ad = list[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (ad.imageUrl != null)
                        Image.network(ad.imageUrl!,
                            height: 140, width: double.infinity, fit: BoxFit.cover),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                                child: Text(ad.title,
                                    style:
                                        Theme.of(context).textTheme.titleMedium)),
                            Chip(
                              label: Text(ad.status),
                              backgroundColor: _statusColor(ad.status),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'active':
        return Colors.green.withValues(alpha: 0.2);
      case 'rejected':
        return Colors.red.withValues(alpha: 0.2);
      default:
        return Colors.orange.withValues(alpha: 0.2);
    }
  }
}
