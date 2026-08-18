import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_exception.dart';
import '../../core/providers/queue_provider.dart';
import '../booking/booking_detail_screen.dart';

class ManualCheckInScreen extends ConsumerStatefulWidget {
  const ManualCheckInScreen({super.key});

  @override
  ConsumerState<ManualCheckInScreen> createState() =>
      _ManualCheckInScreenState();
}

class _ManualCheckInScreenState extends ConsumerState<ManualCheckInScreen> {
  final _bookingId = TextEditingController();
  final _phone = TextEditingController();
  bool _busy = false;
  String? _error;

  Future<void> _submit() async {
    final bookingId = _bookingId.text.trim();
    final phone = _phone.text.trim();
    if (bookingId.isEmpty && phone.isEmpty) {
      setState(() => _error = 'Enter a booking ID or phone number');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final booking = await ref.read(checkInServiceProvider).checkInManual(
          bookingId: bookingId.isEmpty ? null : bookingId,
          phone: phone.isEmpty ? null : phone);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Checked in: ${booking.patientName}')));
      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => BookingDetailScreen(bookingId: booking.id)));
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manual Check-in')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _bookingId,
            decoration: const InputDecoration(labelText: 'Booking ID'),
          ),
          const SizedBox(height: 16),
          const Row(children: [
            Expanded(child: Divider()),
            Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('OR')),
            Expanded(child: Divider()),
          ]),
          const SizedBox(height: 16),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration:
                const InputDecoration(labelText: 'Patient phone number'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Check in'),
          ),
        ],
      ),
    );
  }
}
