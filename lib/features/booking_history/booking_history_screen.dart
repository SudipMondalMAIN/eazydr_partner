import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/facility_provider.dart';
import '../../core/providers/queue_provider.dart';
import '../../core/models/booking.dart';
import '../../core/theme/app_theme.dart';
import '../booking/booking_detail_screen.dart';

const _statusFilters = [
  ('All', null),
  ('Pending', 'pending'),
  ('Confirmed', 'confirmed'),
  ('Checked in', 'checked_in'),
  ('In progress', 'in_progress'),
  ('Completed', 'completed'),
  ('Cancelled', 'cancelled'),
  ('No show', 'no_show'),
];

class BookingHistoryScreen extends ConsumerStatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  ConsumerState<BookingHistoryScreen> createState() =>
      _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends ConsumerState<BookingHistoryScreen> {
  String? _facilityId;
  String? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final facilities = ref.watch(myFacilitiesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Booking History')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: facilities.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Failed to load facilities: $e'),
              data: (list) {
                if (list.isEmpty) {
                  return const Text('Add a facility first.');
                }
                _facilityId ??= list.first.id;
                return DropdownButtonFormField<String>(
                  initialValue: _facilityId,
                  decoration: const InputDecoration(labelText: 'Facility'),
                  items: list
                      .map((f) =>
                          DropdownMenuItem(value: f.id, child: Text(f.name)))
                      .toList(),
                  onChanged: (v) => setState(() => _facilityId = v),
                );
              },
            ),
          ),
          if (_facilityId != null) ...[
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _statusFilters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final (label, value) = _statusFilters[i];
                  final selected = _statusFilter == value;
                  return ChoiceChip(
                    label: Text(label),
                    selected: selected,
                    onSelected: (_) => setState(() => _statusFilter = value),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Consumer(builder: (context, ref, _) {
                final params = FacilityBookingsParams(_facilityId!,
                    status: _statusFilter);
                final bookings = ref.watch(facilityBookingsProvider(params));
                return bookings.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Failed to load: $e')),
                  data: (list) {
                    if (list.isEmpty) {
                      return const Center(
                          child: Text('No bookings found.'));
                    }
                    return RefreshIndicator(
                      onRefresh: () async =>
                          ref.invalidate(facilityBookingsProvider(params)),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                        itemCount: list.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, i) =>
                            _BookingHistoryTile(item: list[i]),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}

class _BookingHistoryTile extends StatelessWidget {
  final BookingListItem item;
  const _BookingHistoryTile({required this.item});

  Color _statusColor(BuildContext context) {
    final tokens = context.tokens;
    switch (item.status) {
      case 'completed':
        return tokens.successColor;
      case 'cancelled':
      case 'no_show':
        return tokens.dangerColor;
      case 'in_progress':
      case 'checked_in':
        return tokens.accentColor;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  String _statusLabel() {
    switch (item.status) {
      case 'in_progress':
        return 'In progress';
      case 'checked_in':
        return 'Checked in';
      case 'no_show':
        return 'No show';
      default:
        return item.status.isEmpty
            ? '—'
            : item.status[0].toUpperCase() + item.status.substring(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final color = _statusColor(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => BookingDetailScreen(bookingId: item.id))),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(kRadiusSm),
                ),
                child: Text(
                  item.tokenNumber > 0 ? '#${item.tokenNumber}' : '—',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: color, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(item.patientName,
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(_statusLabel(),
                              style: theme.textTheme.labelSmall
                                  ?.copyWith(color: color)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('Dr. ${item.doctorName}',
                        style: theme.textTheme.bodySmall),
                    const SizedBox(height: 2),
                    Text(
                      '${item.appointmentDate} · ${item.expectedTime} · ₹${item.bookingFee.toStringAsFixed(0)}',
                      style:
                          theme.textTheme.bodySmall?.copyWith(color: tokens.text3),
                    ),
                    if (item.bookingCode.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(item.bookingCode,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: tokens.text3)),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: tokens.text3),
            ],
          ),
        ),
      ),
    );
  }
}
