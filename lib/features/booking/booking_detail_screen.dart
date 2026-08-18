import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/providers/queue_provider.dart';

class BookingDetailScreen extends ConsumerWidget {
  final String bookingId;
  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booking = ref.watch(bookingDetailProvider(bookingId));

    return Scaffold(
      appBar: AppBar(title: const Text('Booking')),
      body: booking.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load: $e')),
        data: (b) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(b.patientName,
                            style: Theme.of(context).textTheme.titleLarge),
                        Chip(label: Text(b.status)),
                      ],
                    ),
                    if (b.patientPhone != null) Text(b.patientPhone!),
                    const Divider(height: 28),
                    _row('Doctor', b.doctorName),
                    _row('Facility', b.facilityName),
                    if (b.tokenNumber != null) _row('Token', b.tokenNumber!),
                    if (b.appointmentDate != null)
                      _row('Date', b.appointmentDate!),
                    if (b.appointmentTime != null)
                      _row('Time', b.appointmentTime!),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () async {
                final receiptUrl = ref
                    .read(bookingReceiptProvider(bookingId))
                    .maybeWhen(
                        data: (data) =>
                            data['receipt_url'] ?? data['url'] ?? b.receiptUrl,
                        orElse: () => b.receiptUrl);
                if (receiptUrl != null) {
                  await launchUrl(Uri.parse(receiptUrl),
                      mode: LaunchMode.externalApplication);
                } else {
                  ref.invalidate(bookingReceiptProvider(bookingId));
                  final data =
                      await ref.read(bookingReceiptProvider(bookingId).future);
                  final url = data['receipt_url'] ?? data['url'];
                  if (url != null) {
                    await launchUrl(Uri.parse(url),
                        mode: LaunchMode.externalApplication);
                  }
                }
              },
              icon: const Icon(Icons.receipt_long_rounded),
              label: const Text('View / print receipt (with QR)'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
                width: 90,
                child: Text(label, style: const TextStyle(color: Colors.grey))),
            Expanded(child: Text(value)),
          ],
        ),
      );
}
