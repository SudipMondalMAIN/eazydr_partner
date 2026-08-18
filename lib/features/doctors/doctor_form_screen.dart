import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/facility_provider.dart';
import '../../core/models/doctor.dart';

class DoctorFormScreen extends ConsumerStatefulWidget {
  final String facilityId;

  /// When provided, the form edits this existing doctor instead of
  /// adding a new one.
  final Doctor? doctor;

  const DoctorFormScreen({super.key, required this.facilityId, this.doctor});

  bool get isEdit => doctor != null;

  @override
  ConsumerState<DoctorFormScreen> createState() => _DoctorFormScreenState();
}

class _DoctorFormScreenState extends ConsumerState<DoctorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.doctor?.name ?? '');
  late final _specialty =
      TextEditingController(text: widget.doctor?.specialty ?? '');
  late final _qualification =
      TextEditingController(text: widget.doctor?.qualification ?? '');
  late final _fee = TextEditingController(
      text: widget.doctor?.consultationFee?.toString() ?? '');
  bool _saving = false;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (widget.isEdit) {
        await ref
            .read(facilityDoctorsProvider(widget.facilityId).notifier)
            .updateDoctor(
              widget.doctor!.id,
              name: _name.text.trim(),
              specialty: _specialty.text.trim(),
              qualification: _qualification.text.trim().isEmpty
                  ? null
                  : _qualification.text.trim(),
              consultationFee: num.tryParse(_fee.text.trim()),
            );
      } else {
        await ref
            .read(facilityDoctorsProvider(widget.facilityId).notifier)
            .addDoctor(
              name: _name.text.trim(),
              specialty: _specialty.text.trim(),
              qualification: _qualification.text.trim(),
              consultationFee: num.tryParse(_fee.text.trim()),
            );
      }
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
      appBar:
          AppBar(title: Text(widget.isEdit ? 'Edit Doctor' : 'Add Doctor')),
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
              decoration: const InputDecoration(labelText: 'Qualification'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
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
                  : Text(widget.isEdit ? 'Save changes' : 'Save doctor'),
            ),
          ],
        ),
      ),
    );
  }
}
