import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/facility_provider.dart';
import 'facility_form_screen.dart';
import 'facility_detail_screen.dart';

class FacilitiesListScreen extends ConsumerWidget {
  const FacilitiesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facilities = ref.watch(myFacilitiesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Facilities')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const FacilityFormScreen()));
          ref.read(myFacilitiesProvider.notifier).refresh();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add facility'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(myFacilitiesProvider.notifier).refresh(),
        child: facilities.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(children: [
            const SizedBox(height: 80),
            Center(child: Text('Failed to load: $e')),
          ]),
          data: (list) {
            if (list.isEmpty) {
              return ListView(children: const [
                SizedBox(height: 100),
                Center(child: Text('No facilities yet — add your first one.')),
              ]);
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final f = list[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: CircleAvatar(
                      backgroundImage:
                          f.photoUrl != null ? NetworkImage(f.photoUrl!) : null,
                      child: f.photoUrl == null
                          ? const Icon(Icons.local_hospital_rounded)
                          : null,
                    ),
                    title: Text(f.name),
                    subtitle: Text('${f.type} · ${f.city}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => FacilityDetailScreen(facilityId: f.id))),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
