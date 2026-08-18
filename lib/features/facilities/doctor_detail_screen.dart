import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/api/api_exception.dart';
import '../../core/core_providers.dart';
import '../../core/models/facility.dart';
import '../../core/theme/app_theme.dart';
import 'facilities_provider.dart';

class DoctorDetailScreen extends ConsumerStatefulWidget {
  final Doctor doctor;
  final String facilityId;
  const DoctorDetailScreen({super.key, required this.doctor, required this.facilityId});

  @override
  ConsumerState<DoctorDetailScreen> createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends ConsumerState<DoctorDetailScreen> {
  late bool _isActive = widget.doctor.isActive;
  String? _photoUrl = widget.doctor.photoUrl;
  bool _uploadingPhoto = false;
  List<AvailabilitySlot>? _slots;
  bool _loadingSlots = true;

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    setState(() => _uploadingPhoto = true);
    try {
      final updated = await ref.read(doctorsProvider(widget.facilityId).notifier).uploadDoctorPhoto(widget.doctor.id, picked.path);
      setState(() => _photoUrl = updated.photoUrl);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo upload failed')));
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  Future<void> _loadSlots() async {
    setState(() => _loadingSlots = true);
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get('/api/v1/facilities/doctors/${widget.doctor.id}/availability');
      _slots = (res.data as List).map((e) => AvailabilitySlot.fromJson(e)).toList();
    } catch (_) {
      _slots = [];
    } finally {
      if (mounted) setState(() => _loadingSlots = false);
    }
  }

  Future<void> _toggleActive(bool value) async {
    setState(() => _isActive = value);
    try {
      final api = ref.read(apiClientProvider);
      await api.patch('/api/v1/facilities/doctors/${widget.doctor.id}', data: {'is_active': value});
      ref.read(doctorsProvider(widget.facilityId).notifier).refresh();
    } catch (_) {
      setState(() => _isActive = !value);
    }
  }

  void _showAddSlotSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddSlotSheet(doctorId: widget.doctor.id, onAdded: _loadSlots),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.doctor;
    return Scaffold(
      appBar: AppBar(title: Text(d.fullName)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSlotSheet,
        icon: const Icon(Icons.add_alarm_rounded),
        label: const Text('Add slot'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Center(
                  child: GestureDetector(
                    onTap: _uploadingPhoto ? null : _pickAndUploadPhoto,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
                          child: _photoUrl == null ? const Icon(Icons.person_rounded, size: 32) : null,
                        ),
                        if (_uploadingPhoto)
                          const CircularProgressIndicator()
                        else
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Theme.of(context).cardColor, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(d.fullName, style: Theme.of(context).textTheme.titleLarge),
                Text('${d.specialty} · ${d.qualification}', style: Theme.of(context).textTheme.bodyMedium),
                Text('Consultation fee: ₹${d.consultationFee.toStringAsFixed(0)}', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
                Row(children: [
                  const Text('Accepting bookings'),
                  const Spacer(),
                  Switch(value: _isActive, onChanged: _toggleActive),
                ]),
              ]),
            ),
          ),
          const SizedBox(height: 20),
          Text('Availability', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_loadingSlots)
            const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
          else if (_slots == null || _slots!.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text('No availability set yet', style: TextStyle(color: context.tokens.text2)),
            )
          else
            ..._slots!.map((s) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(s.isLeave ? Icons.event_busy_rounded : Icons.schedule_rounded),
                    title: Text(s.isLeave
                        ? 'Leave — ${s.leaveDate ?? ''}'
                        : '${s.dayOfWeek != null ? AvailabilitySlot.dayNames[s.dayOfWeek!] : 'Every day'}  ${s.startTime}–${s.endTime}'),
                    subtitle: s.isLeave ? null : Text('${s.slotDurationMinutes} min slots'),
                  ),
                )),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _AddSlotSheet extends ConsumerStatefulWidget {
  final String doctorId;
  final VoidCallback onAdded;
  const _AddSlotSheet({required this.doctorId, required this.onAdded});
  @override
  ConsumerState<_AddSlotSheet> createState() => _AddSlotSheetState();
}

class _AddSlotSheetState extends ConsumerState<_AddSlotSheet> {
  int? _dow = 0;
  final _start = TextEditingController(text: '09:00');
  final _end = TextEditingController(text: '17:00');
  final _duration = TextEditingController(text: '15');
  bool _isLeave = false;
  final _leaveDate = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      await api.post('/api/v1/facilities/doctors/${widget.doctorId}/availability', data: {
        'day_of_week': _isLeave ? null : _dow,
        'start_time': _start.text.trim(),
        'end_time': _end.text.trim(),
        'slot_duration_minutes': int.tryParse(_duration.text) ?? 15,
        'is_leave': _isLeave,
        if (_isLeave) 'leave_date': _leaveDate.text.trim(),
      });
      widget.onAdded();
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
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 16),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Add availability', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('This is a leave day'),
            value: _isLeave,
            onChanged: (v) => setState(() => _isLeave = v),
          ),
          if (_isLeave)
            TextField(controller: _leaveDate, decoration: const InputDecoration(labelText: 'Leave date (YYYY-MM-DD)'))
          else ...[
            DropdownButtonFormField<int>(
              value: _dow,
              decoration: const InputDecoration(labelText: 'Day of week'),
              items: List.generate(7, (i) => i)
                  .map((i) => DropdownMenuItem(value: i, child: Text(AvailabilitySlot.dayNames[i])))
                  .toList(),
              onChanged: (v) => setState(() => _dow = v),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextField(controller: _start, decoration: const InputDecoration(labelText: 'Start (HH:MM)'))),
              const SizedBox(width: 12),
              Expanded(child: TextField(controller: _end, decoration: const InputDecoration(labelText: 'End (HH:MM)'))),
            ]),
            const SizedBox(height: 12),
            TextField(controller: _duration, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Slot duration (minutes)')),
          ],
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Save'),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}
