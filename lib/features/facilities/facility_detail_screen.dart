import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/providers/facility_provider.dart';
import '../doctors/doctor_form_screen.dart';
import '../doctors/doctor_availability_screen.dart';
import '../reviews/review_list_screen.dart';
import '../../core/providers/review_provider.dart';

class FacilityDetailScreen extends ConsumerWidget {
  final String facilityId;
  const FacilityDetailScreen({super.key, required this.facilityId});

  Future<void> _pickAndUploadPhoto(BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    try {
      await ref
          .read(myFacilitiesProvider.notifier)
          .uploadPhoto(facilityId, File(picked.path));
      ref.invalidate(facilityDetailProvider(facilityId));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facility = ref.watch(facilityDetailProvider(facilityId));
    final doctors = ref.watch(facilityDoctorsProvider(facilityId));

    return Scaffold(
      appBar: AppBar(title: const Text('Facility')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => DoctorFormScreen(facilityId: facilityId)));
          ref.read(facilityDoctorsProvider(facilityId).notifier).refresh();
        },
        icon: const Icon(Icons.person_add_alt_rounded),
        label: const Text('Add doctor'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        children: [
          facility.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Failed to load: $e'),
            data: (f) => Column(
              children: [
                GestureDetector(
                  onTap: () => _pickAndUploadPhoto(context, ref),
                  child: CircleAvatar(
                    radius: 44,
                    backgroundImage:
                        f.photoUrl != null ? NetworkImage(f.photoUrl!) : null,
                    child: f.photoUrl == null
                        ? const Icon(Icons.add_a_photo_rounded, size: 28)
                        : null,
                  ),
                ),
                const SizedBox(height: 12),
                Text(f.name, style: Theme.of(context).textTheme.titleLarge),
                Text('${f.type} · ${f.city}',
                    style: Theme.of(context).textTheme.bodyMedium),
                Text(f.address, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ReviewListScreen(
                          target: ReviewTarget('facility', facilityId),
                          title: f.name))),
                  icon: const Icon(Icons.star_rounded, size: 18),
                  label: const Text('View reviews'),
                ),
              ],
            ),
          ),
          const Divider(height: 32),
          Text('Doctors', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          doctors.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('Failed to load doctors: $e'),
            data: (list) {
              if (list.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No doctors added yet.'),
                );
              }
              return Column(
                children: list
                    .map((d) => Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: d.photoUrl != null
                                  ? NetworkImage(d.photoUrl!)
                                  : null,
                              child: d.photoUrl == null
                                  ? const Icon(Icons.person_rounded)
                                  : null,
                            ),
                            title: Text(d.name),
                            subtitle: Text(d.specialty),
                            trailing: const Icon(Icons.schedule_rounded),
                            onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => DoctorAvailabilityScreen(
                                        doctorId: d.id, doctorName: d.name))),
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
