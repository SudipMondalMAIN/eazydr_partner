import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/providers/ads_provider.dart';
import '../../core/providers/facility_provider.dart';

class AdFormScreen extends ConsumerStatefulWidget {
  const AdFormScreen({super.key});

  @override
  ConsumerState<AdFormScreen> createState() => _AdFormScreenState();
}

class _AdFormScreenState extends ConsumerState<AdFormScreen> {
  final _title = TextEditingController();
  File? _image;
  String? _facilityId;
  bool _saving = false;
  String? _error;

  Future<void> _pickImage() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) setState(() => _image = File(picked.path));
  }

  Future<void> _submit() async {
    if (_title.text.trim().isEmpty || _image == null) {
      setState(() => _error = 'Title and image are required');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(myAdsProvider.notifier).createAd(
            title: _title.text.trim(),
            image: _image!,
            facilityId: _facilityId,
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
    final facilities = ref.watch(myFacilitiesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('New Ad')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
                image: _image != null
                    ? DecorationImage(
                        image: FileImage(_image!), fit: BoxFit.cover)
                    : null,
              ),
              child: _image == null
                  ? const Center(
                      child: Icon(Icons.add_photo_alternate_rounded, size: 36))
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Ad title'),
          ),
          const SizedBox(height: 14),
          facilities.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => const SizedBox.shrink(),
            data: (list) => DropdownButtonFormField<String>(
              initialValue: _facilityId,
              decoration:
                  const InputDecoration(labelText: 'Facility (optional)'),
              items: list
                  .map((f) =>
                      DropdownMenuItem(value: f.id, child: Text(f.name)))
                  .toList(),
              onChanged: (v) => setState(() => _facilityId = v),
            ),
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
                : const Text('Submit ad'),
          ),
        ],
      ),
    );
  }
}
