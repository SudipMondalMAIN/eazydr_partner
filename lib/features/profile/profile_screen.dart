import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/core_providers.dart';
import '../../core/routing/route_names.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _uploadingPhoto = false;

  Future<void> _pickAndUploadPhoto() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;
    setState(() => _uploadingPhoto = true);
    try {
      final api = ref.read(apiClientProvider);
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(File(picked.path).path),
      });
      await api.postForm('/api/v1/auth/me/photo', form);
      await ref.read(authProvider.notifier).refreshCurrentUser();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: GestureDetector(
              onTap: _uploadingPhoto ? null : _pickAndUploadPhoto,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundImage: user?.photoUrl != null
                        ? NetworkImage(user!.photoUrl!)
                        : null,
                    child: user?.photoUrl == null
                        ? const Icon(Icons.person_rounded, size: 40)
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: CircleAvatar(
                      radius: 16,
                      child: _uploadingPhoto
                          ? const SizedBox(
                              height: 14,
                              width: 14,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.camera_alt_rounded, size: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (user != null) ...[
            Center(
              child: Text(user.fullName,
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            const SizedBox(height: 4),
            Center(child: Text(user.email)),
            Center(child: Text(user.phone)),
            const SizedBox(height: 24),
          ],
          OutlinedButton(
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go(Routes.auth);
            },
            child: const Text('Log out'),
          ),
        ],
      ),
    );
  }
}
