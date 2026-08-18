import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/routing/route_names.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (user != null) ...[
            Text(user.fullName, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(user.email, style: Theme.of(context).textTheme.bodyMedium),
            Text(user.phone, style: Theme.of(context).textTheme.bodyMedium),
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
