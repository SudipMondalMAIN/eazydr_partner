import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
                        Expanded(
                          child: Text(b.patientName,
                              style: Theme.of(context).textTheme.titleLarge),
                        ),
                        Chip(label: Text(b.status)),
                      ],
                    ),
                    if (b.patientPhone != null) Text(b.patientPhone!),
                    const Divider(height: 28),
                    _row('Booking code', b.bookingCode),
                    _row('Doctor', b.doctorName),
                    _row('Facility', b.facilityName),
                    if (b.facilityAddress.isNotEmpty)
                      _row('Address', b.facilityAddress),
                    if (b.tokenNumber.isNotEmpty)
                      _row('Token', b.tokenNumber),
                    if (b.appointmentDate.isNotEmpty)
                      _row('Date', b.appointmentDate),
                    if (b.expectedTime.isNotEmpty)
                      _row('Time', b.expectedTime),
                  ],
                ),
              ),
            ),
            if (b.qrCodeBase64 != null && b.qrCodeBase64!.isNotEmpty) ...[
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Text('Booking QR', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      Image.memory(base64Decode(b.qrCodeBase64!), width: 200, height: 200),
                    ],
                  ),
                ),
              ),
            ],
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
                width: 100,
                child: Text(label, style: const TextStyle(color: Colors.grey))),
            Expanded(child: Text(value)),
          ],
        ),
      );
}
