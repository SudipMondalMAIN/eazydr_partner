import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/queue_provider.dart';

class BookingDetailScreen extends ConsumerStatefulWidget {
  final String bookingId;
  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  ConsumerState<BookingDetailScreen> createState() =>
      _BookingDetailScreenState();
}

class _BookingDetailScreenState extends ConsumerState<BookingDetailScreen> {
  bool _busy = false;
  String? _error;
  String? _statusOverride;

  Future<void> _startConsultation() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(checkInServiceProvider)
          .startConsultation(widget.bookingId);
      setState(() => _statusOverride = result.status);
      ref.invalidate(bookingDetailProvider(widget.bookingId));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _completeConsultation() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(checkInServiceProvider)
          .completeConsultation(widget.bookingId);
      setState(() => _statusOverride = result.status);
      ref.invalidate(bookingDetailProvider(widget.bookingId));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = ref.watch(bookingDetailProvider(widget.bookingId));

    return Scaffold(
      appBar: AppBar(title: const Text('Booking')),
      body: booking.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load: $e')),
        data: (b) {
          final status = _statusOverride ?? b.status;
          return ListView(
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
                          Chip(label: Text(status)),
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
              if (status == 'checked_in' || status == 'in_progress') ...[
                const SizedBox(height: 20),
                if (_error != null) ...[
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 10),
                ],
                if (status == 'checked_in')
                  FilledButton.icon(
                    onPressed: _busy ? null : _startConsultation,
                    icon: _busy
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.play_arrow_rounded),
                    label: const Text('Start consultation'),
                  ),
                if (status == 'in_progress')
                  FilledButton.icon(
                    onPressed: _busy ? null : _completeConsultation,
                    icon: _busy
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.check_circle_rounded),
                    label: const Text('Complete consultation'),
                  ),
              ],
              if (b.qrCodeBase64 != null && b.qrCodeBase64!.isNotEmpty) ...[
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        Text('Booking QR',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        Image.memory(base64Decode(b.qrCodeBase64!),
                            width: 200, height: 200),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          );
        },
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
