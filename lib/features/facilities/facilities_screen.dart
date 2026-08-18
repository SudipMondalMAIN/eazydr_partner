import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_exception.dart';
import '../../core/models/facility.dart';
import '../../core/theme/app_theme.dart';
import 'facilities_provider.dart';
import 'facility_detail_screen.dart';

class FacilitiesScreen extends ConsumerWidget {
  const FacilitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facilitiesAsync = ref.watch(facilitiesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Facilities'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showCreateSheet(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(facilitiesProvider.notifier).refresh(),
        child: facilitiesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(children: [
            const SizedBox(height: 80),
            Center(child: Text('Failed to load: $e')),
          ]),
          data: (facilities) {
            if (facilities.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 100),
                  Center(
                    child: Column(children: [
                      Icon(Icons.storefront_outlined,
                          size: 56, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(height: 12),
                      const Text('No facilities yet'),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: () => _showCreateSheet(context, ref),
                        child: const Text('Add your first facility'),
                      ),
                    ]),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: facilities.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final f = facilities[i];
                return Dismissible(
                  key: ValueKey(f.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: context.tokens.dangerColor,
                      borderRadius: BorderRadius.circular(kRadius),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                  ),
                  confirmDismiss: (_) => _confirmDelete(context, f.name),
                  onDismissed: (_) => ref.read(facilitiesProvider.notifier).deleteFacility(f.id),
                  child: Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(14),
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                        backgroundImage: f.photoUrl != null ? NetworkImage(f.photoUrl!) : null,
                        child: f.photoUrl == null
                            ? Icon(Icons.local_hospital_rounded, color: Theme.of(context).colorScheme.primary)
                            : null,
                      ),
                      title: Text(f.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('${f.facilityType} · ${f.city}\n${f.address}'),
                      isThreeLine: true,
                      trailing: f.isVerified
                          ? const Icon(Icons.verified_rounded, color: Colors.teal, size: 20)
                          : Icon(Icons.hourglass_top_rounded, size: 18, color: context.tokens.text2),
                      onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => FacilityDetailScreen(facility: f))),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, String name) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete facility?'),
        content: Text('"$name" will be removed from your list and hidden from patients. '
            'Doctors, bookings and earnings history are kept.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showCreateSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _CreateFacilitySheet(),
    );
  }
}

class _CreateFacilitySheet extends ConsumerStatefulWidget {
  const _CreateFacilitySheet();
  @override
  ConsumerState<_CreateFacilitySheet> createState() => _CreateFacilitySheetState();
}

class _CreateFacilitySheetState extends ConsumerState<_CreateFacilitySheet> {
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController(text: 'Bolpur');
  final _lat = TextEditingController();
  final _lng = TextEditingController();
  final _fee = TextEditingController(text: '10');
  final _phone = TextEditingController();
  final _email = TextEditingController();
  String _type = 'nursing_home';
  bool _loading = false;
  String? _error;

  static const _types = ['nursing_home', 'doctor_chamber', 'pharmacy'];

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty || _address.text.trim().isEmpty || _lat.text.isEmpty || _lng.text.isEmpty) {
      setState(() => _error = 'Name, address, latitude and longitude are required');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(facilitiesProvider.notifier).createFacility(
            name: _name.text.trim(),
            facilityType: _type,
            address: _address.text.trim(),
            city: _city.text.trim().isEmpty ? 'Bolpur' : _city.text.trim(),
            latitude: double.tryParse(_lat.text) ?? 0,
            longitude: double.tryParse(_lng.text) ?? 0,
            bookingFee: double.tryParse(_fee.text) ?? 10,
            phone: _phone.text.trim(),
            email: _email.text.trim(),
          );
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Something went wrong');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: context.tokens.border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text('Add facility', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              _label('Facility type'),
              DropdownButtonFormField<String>(
                value: _type,
                items: _types
                    .map((t) => DropdownMenuItem(value: t, child: Text(t.replaceAll('_', ' '))))
                    .toList(),
                onChanged: (v) => setState(() => _type = v ?? _type),
              ),
              const SizedBox(height: 12),
              _label('Name'),
              TextField(controller: _name, decoration: const InputDecoration(hintText: 'e.g. Sunrise Clinic')),
              const SizedBox(height: 12),
              _label('Address'),
              TextField(controller: _address, maxLines: 2, decoration: const InputDecoration(hintText: 'Full address')),
              const SizedBox(height: 12),
              _label('City'),
              TextField(controller: _city),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _label('Latitude'),
                    TextField(controller: _lat, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true)),
                  ]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _label('Longitude'),
                    TextField(controller: _lng, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true)),
                  ]),
                ),
              ]),
              const SizedBox(height: 12),
              _label('Booking fee (₹)'),
              TextField(controller: _fee, keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              _label('Phone (optional)'),
              TextField(controller: _phone, keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              _label('Email (optional)'),
              TextField(controller: _email, keyboardType: TextInputType.emailAddress),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Create facility'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      );
}
