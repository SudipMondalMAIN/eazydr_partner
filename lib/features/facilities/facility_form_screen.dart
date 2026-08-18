import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/facility_provider.dart';
import '../../core/models/facility.dart';

class FacilityFormScreen extends ConsumerStatefulWidget {
  /// When provided, the form edits this existing facility instead of
  /// creating a new one.
  final Facility? facility;

  const FacilityFormScreen({super.key, this.facility});

  bool get isEdit => facility != null;

  @override
  ConsumerState<FacilityFormScreen> createState() =>
      _FacilityFormScreenState();
}

class _FacilityFormScreenState extends ConsumerState<FacilityFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name =
      TextEditingController(text: widget.facility?.name ?? '');
  late final _address =
      TextEditingController(text: widget.facility?.address ?? '');
  late final _city = TextEditingController(text: widget.facility?.city ?? '');
  late final _phone = TextEditingController(text: widget.facility?.phone ?? '');
  late String _type = widget.facility?.type ?? 'Clinic';
  bool _saving = false;
  String? _error;

  static const _types = ['Clinic', 'Hospital', 'Diagnostic Center', 'Pharmacy'];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (widget.isEdit) {
        await ref.read(myFacilitiesProvider.notifier).editFacility(
              widget.facility!.id,
              name: _name.text.trim(),
              address: _address.text.trim(),
              city: _city.text.trim(),
              phone: _phone.text.trim(),
            );
      } else {
        await ref.read(myFacilitiesProvider.notifier).create(
              name: _name.text.trim(),
              type: _type,
              address: _address.text.trim(),
              city: _city.text.trim(),
              phone: _phone.text.trim(),
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
          AppBar(title: Text(widget.isEdit ? 'Edit Facility' : 'Add Facility')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Facility name'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Name is required'
                  : null,
            ),
            const SizedBox(height: 14),
            if (!widget.isEdit) ...[
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: _types
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _type = v ?? _type),
              ),
              const SizedBox(height: 14),
            ],
            TextFormField(
              controller: _address,
              decoration: const InputDecoration(labelText: 'Address'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Address is required'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _city,
              decoration: const InputDecoration(labelText: 'City'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'City is required' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phone,
              decoration: const InputDecoration(labelText: 'Phone (optional)'),
              keyboardType: TextInputType.phone,
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
                  : Text(widget.isEdit ? 'Save changes' : 'Save facility'),
            ),
          ],
        ),
      ),
    );
  }
}
