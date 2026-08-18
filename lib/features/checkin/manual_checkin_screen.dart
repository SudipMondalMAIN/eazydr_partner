import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_exception.dart';
import '../../core/providers/facility_provider.dart';
import '../../core/providers/queue_provider.dart';
import '../booking/booking_detail_screen.dart';

class ManualCheckInScreen extends ConsumerStatefulWidget {
  const ManualCheckInScreen({super.key});

  @override
  ConsumerState<ManualCheckInScreen> createState() =>
      _ManualCheckInScreenState();
}

class _ManualCheckInScreenState extends ConsumerState<ManualCheckInScreen> {
  String? _facilityId;
  String? _doctorId;
  DateTime _date = DateTime.now();
  final _bookingId = TextEditingController();
  final _phone = TextEditingController();
  bool _busy = false;
  String? _error;

  String get _formattedDate =>
      '${_date.year.toString().padLeft(4, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (_doctorId == null) {
      setState(() => _error = 'Select the doctor');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await ref.read(checkInServiceProvider).checkInManual(
            doctorId: _doctorId!,
            appointmentDate: _formattedDate,
            bookingId:
                _bookingId.text.trim().isEmpty ? null : _bookingId.text.trim(),
            patientPhone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Checked in: ${result.patientName}')));
      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => BookingDetailScreen(bookingId: result.bookingId)));
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final facilities = ref.watch(myFacilitiesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manual Check-in')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          facilities.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Failed to load facilities: $e'),
            data: (list) {
              if (list.isEmpty) return const Text('Add a facility first.');
              _facilityId ??= list.first.id;
              return DropdownButtonFormField<String>(
                initialValue: _facilityId,
                decoration: const InputDecoration(labelText: 'Facility'),
                items: list
                    .map((f) =>
                        DropdownMenuItem(value: f.id, child: Text(f.name)))
                    .toList(),
                onChanged: (v) => setState(() {
                  _facilityId = v;
                  _doctorId = null;
                }),
              );
            },
          ),
          const SizedBox(height: 14),
          if (_facilityId != null)
            Consumer(builder: (context, ref, _) {
              final doctors = ref.watch(facilityDoctorsProvider(_facilityId!));
              return doctors.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Failed to load doctors: $e'),
                data: (list) {
                  if (list.isEmpty) {
                    return const Text('No doctors under this facility.');
                  }
                  _doctorId ??= list.first.id;
                  return DropdownButtonFormField<String>(
                    initialValue: _doctorId,
                    decoration: const InputDecoration(labelText: 'Doctor'),
                    items: list
                        .map((d) =>
                            DropdownMenuItem(value: d.id, child: Text(d.name)))
                        .toList(),
                    onChanged: (v) => setState(() => _doctorId = v),
                  );
                },
              );
            }),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today_rounded),
            label: Text('Appointment date: $_formattedDate'),
          ),
          const SizedBox(height: 20),
          const Row(children: [
            Expanded(child: Divider()),
            Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('Identify the patient (optional)')),
            Expanded(child: Divider()),
          ]),
          const SizedBox(height: 16),
          TextField(
            controller: _bookingId,
            decoration: const InputDecoration(labelText: 'Booking ID'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration:
                const InputDecoration(labelText: 'Patient phone number'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Check in'),
          ),
        ],
      ),
    );
  }
}
