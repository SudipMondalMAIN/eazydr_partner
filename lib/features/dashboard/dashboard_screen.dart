import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/providers/notification_provider.dart';
import '../../core/providers/facility_provider.dart';
import '../../core/theme/app_theme.dart';
import '../facilities/facilities_list_screen.dart';
import '../ads/ads_screen.dart';
import '../notifications/notifications_screen.dart';
import '../reviews/reviews_hub_screen.dart';
import '../checkin/manual_checkin_screen.dart';
import '../queue/queue_screen.dart';
import '../earnings/earnings_screen.dart';
import '../booking_history/booking_history_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final unread = ref.watch(unreadCountProvider);
    final facilities = ref.watch(myFacilitiesProvider);
    final theme = Theme.of(context);
    final tokens = context.tokens;

    final tiles = <_Tile>[
      _Tile('Facilities', 'Manage your listings', Icons.local_hospital_rounded,
          (c) => const FacilitiesListScreen()),
      _Tile('Live queue', 'Today\'s token status', Icons.groups_rounded,
          (c) => const QueueScreen()),
      _Tile('Manual check-in', 'Walk-in patients', Icons.how_to_reg_rounded,
          (c) => const ManualCheckInScreen()),
      _Tile('Booking history', 'Past & upcoming visits', Icons.history_rounded,
          (c) => const BookingHistoryScreen()),
      _Tile('Earnings', 'Track your payouts', Icons.account_balance_wallet_rounded,
          (c) => const EarningsScreen()),
      _Tile('Sponsored ads', 'Boost visibility', Icons.campaign_rounded,
          (c) => const AdsScreen()),
      _Tile('Reviews & ratings', 'See patient feedback', Icons.star_rounded,
          (c) => const ReviewsHubScreen()),
    ];

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(myFacilitiesProvider);
            ref.invalidate(unreadCountProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _GreetingHeader(
                name: user?.fullName.split(' ').first ?? 'Partner',
                unreadCount: unread.maybeWhen(data: (n) => n, orElse: () => 0),
                onNotificationsTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NotificationsScreen())),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.local_hospital_rounded,
                      label: 'Facilities',
                      value: facilities.maybeWhen(
                        data: (list) => '${list.length}',
                        orElse: () => '—',
                      ),
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.notifications_rounded,
                      label: 'Unread',
                      value: unread.maybeWhen(
                        data: (n) => '$n',
                        orElse: () => '—',
                      ),
                      color: tokens.accentColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Quick actions',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.05,
                ),
                itemCount: tiles.length,
                itemBuilder: (context, i) => _ActionTile(tile: tiles[i]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Gradient greeting card — mirrors the patient app's hero-style header so
/// the partner app opens with the same warmth instead of a bare app bar.
class _GreetingHeader extends StatelessWidget {
  final String name;
  final int unreadCount;
  final VoidCallback onNotificationsTap;

  const _GreetingHeader({
    required this.name,
    required this.unreadCount,
    required this.onNotificationsTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primary, secondary],
        ),
        borderRadius: BorderRadius.circular(kRadiusLg),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: Colors.white.withValues(alpha: 0.85))),
                const SizedBox(height: 4),
                Text(name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('Here\'s what\'s happening today',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.white.withValues(alpha: 0.8))),
              ],
            ),
          ),
          _NotificationBell(count: unreadCount, onTap: onNotificationsTap),
        ],
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _NotificationBell({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.18),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_none_rounded, color: Colors.white),
              if (count > 0)
                Positioned(
                  right: -3,
                  top: -3,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                        color: Colors.red, shape: BoxShape.circle),
                    constraints:
                        const BoxConstraints(minWidth: 15, minHeight: 15),
                    child: Text('$count',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small stat summary card — quick glanceable numbers above the action grid.
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(kRadiusSm),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800)),
                Text(label, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Action grid tile — icon in a soft tinted chip, title + subtitle, matching
/// the rounded-card visual language used across the app.
class _ActionTile extends StatelessWidget {
  final _Tile tile;
  const _ActionTile({required this.tile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final primary = theme.colorScheme.primary;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: tile.builder)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(kRadiusSm),
                ),
                child: Icon(tile.icon, size: 24, color: primary),
              ),
              const SizedBox(height: 12),
              Text(tile.label,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(tile.subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(color: tokens.text3),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tile {
  final String label;
  final String subtitle;
  final IconData icon;
  final Widget Function(BuildContext) builder;
  _Tile(this.label, this.subtitle, this.icon, this.builder);
}
