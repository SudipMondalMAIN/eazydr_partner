import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/facility_provider.dart';

class FacilityFormScreen extends ConsumerStatefulWidget {
  const FacilityFormScreen({super.key});

  @override
  ConsumerState<FacilityFormScreen> createState() =>
      _FacilityFormScreenState();
}

class _FacilityFormScreenState extends ConsumerState<FacilityFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _city = TextEditingController();
  final _phone = TextEditingController();
  String _type = 'Clinic';
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
      await ref.read(myFacilitiesProvider.notifier).create(
            name: _name.text.trim(),
            type: _type,
            address: _address.text.trim(),
            city: _city.text.trim(),
            phone: _phone.text.trim(),
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
      appBar: AppBar(title: const Text('Add Facility')),
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
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: _types
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            const SizedBox(height: 14),
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
                  : const Text('Save facility'),
            ),
          ],
        ),
      ),
    );
  }
}
