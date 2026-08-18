import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/notification_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () =>
                ref.read(notificationsProvider.notifier).markAllRead(),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(notificationsProvider.notifier).refresh(),
        child: notifications.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(children: [
            const SizedBox(height: 80),
            Center(child: Text('Failed to load: $e')),
          ]),
          data: (list) {
            if (list.isEmpty) {
              return ListView(children: const [
                SizedBox(height: 100),
                Center(child: Text('No notifications yet.')),
              ]);
            }
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, i) {
                final n = list[i];
                return Card(
                  color: n.isRead
                      ? null
                      : Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.06),
                  child: ListTile(
                    leading: Icon(n.isRead
                        ? Icons.notifications_none_rounded
                        : Icons.notifications_active_rounded),
                    title: Text(n.title,
                        style: TextStyle(
                            fontWeight:
                                n.isRead ? FontWeight.normal : FontWeight.bold)),
                    subtitle: Text(n.body),
                    onTap: () {
                      if (!n.isRead) {
                        ref.read(notificationsProvider.notifier).markRead(n.id);
                      }
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
