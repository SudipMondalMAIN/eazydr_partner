import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/api/api_exception.dart';
import '../../core/providers/queue_provider.dart';
import '../booking/booking_detail_screen.dart';
import '../checkin/manual_checkin_screen.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  final _controller = MobileScannerController();
  bool _busy = false;

  Future<void> _handleCode(String raw) async {
    if (_busy) return;
    setState(() => _busy = true);
    await _controller.stop();
    try {
      final booking =
          await ref.read(checkInServiceProvider).checkInWithQr(raw);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Checked in: ${booking.patientName}')));
      await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => BookingDetailScreen(bookingId: booking.id)));
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Check-in failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
      await _controller.start();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Check-in'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_rounded),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final codes = capture.barcodes;
              if (codes.isNotEmpty && codes.first.rawValue != null) {
                _handleCode(codes.first.rawValue!);
              }
            },
          ),
          if (_busy)
            Container(
              color: Colors.black45,
              child: const Center(
                  child: CircularProgressIndicator(color: Colors.white)),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const ManualCheckInScreen())),
                icon: const Icon(Icons.keyboard_rounded),
                label: const Text('Check in manually instead'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
