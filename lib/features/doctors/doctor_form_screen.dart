import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/facility_provider.dart';

class DoctorFormScreen extends ConsumerStatefulWidget {
  final String facilityId;
  const DoctorFormScreen({super.key, required this.facilityId});

  @override
  ConsumerState<DoctorFormScreen> createState() => _DoctorFormScreenState();
}

class _DoctorFormScreenState extends ConsumerState<DoctorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _specialty = TextEditingController();
  final _qualification = TextEditingController();
  final _experience = TextEditingController();
  final _fee = TextEditingController();
  bool _saving = false;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(facilityDoctorsProvider(widget.facilityId).notifier)
          .addDoctor(
            name: _name.text.trim(),
            specialty: _specialty.text.trim(),
            qualification: _qualification.text.trim().isEmpty
                ? null
                : _qualification.text.trim(),
            experienceYears: int.tryParse(_experience.text.trim()),
            consultationFee: num.tryParse(_fee.text.trim()),
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Doctor')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Doctor name'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _specialty,
              decoration: const InputDecoration(labelText: 'Specialty'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _qualification,
              decoration:
                  const InputDecoration(labelText: 'Qualification (optional)'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _experience,
              decoration: const InputDecoration(
                  labelText: 'Experience (years, optional)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _fee,
              decoration: const InputDecoration(
                  labelText: 'Consultation fee (optional)'),
              keyboardType: TextInputType.number,
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save doctor'),
            ),
          ],
        ),
      ),
    );
  }
}
