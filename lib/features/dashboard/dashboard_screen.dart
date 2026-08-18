import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/providers/notification_provider.dart';
import '../facilities/facilities_list_screen.dart';
import '../ads/ads_screen.dart';
import '../notifications/notifications_screen.dart';
import '../reviews/reviews_hub_screen.dart';
import '../checkin/manual_checkin_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final unread = ref.watch(unreadCountProvider);

    final tiles = <_Tile>[
      _Tile('Facilities', Icons.local_hospital_rounded,
          (c) => const FacilitiesListScreen()),
      _Tile('Manual check-in', Icons.how_to_reg_rounded,
          (c) => const ManualCheckInScreen()),
      _Tile('Sponsored ads', Icons.campaign_rounded, (c) => const AdsScreen()),
      _Tile('Reviews & ratings', Icons.star_rounded,
          (c) => const ReviewsHubScreen()),
      _Tile('Notifications', Icons.notifications_rounded,
          (c) => const NotificationsScreen()),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Hi, ${user?.fullName.split(' ').first ?? 'Partner'}'),
        actions: [
          IconButton(
            icon: badge(
              Icons.notifications_none_rounded,
              unread.maybeWhen(data: (n) => n, orElse: () => 0),
            ),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const NotificationsScreen())),
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 1.15,
        ),
        itemCount: tiles.length,
        itemBuilder: (context, i) {
          final t = tiles[i];
          return Card(
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18)),
            child: InkWell(
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: t.builder)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(t.icon,
                        size: 32,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 12),
                    Text(t.label,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget badge(IconData icon, int count) {
    if (count <= 0) return Icon(icon);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        Positioned(
          right: -4,
          top: -4,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration:
                const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            child: Text('$count',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 10)),
          ),
        ),
      ],
    );
  }
}

class _Tile {
  final String label;
  final IconData icon;
  final Widget Function(BuildContext) builder;
  _Tile(this.label, this.icon, this.builder);
}
