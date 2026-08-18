import 'package:flutter/material.dart';
import '../dashboard/dashboard_screen.dart';
import '../scan/scan_screen.dart';
import '../queue/queue_screen.dart';
import '../earnings/earnings_screen.dart';
import '../profile/profile_screen.dart';

/// Partner app's fixed bottom-nav shell: Dashboard, Scan (QR check-in),
/// Queue, Earnings, Profile — unlike the patient app this isn't
/// backend-config-driven since the merchant's core workflow is fixed.
class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _screens = [
    DashboardScreen(),
    ScanScreen(),
    QueueScreen(),
    EarningsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner_rounded), label: 'Scan'),
          BottomNavigationBarItem(
              icon: Icon(Icons.people_alt_rounded), label: 'Queue'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_rounded),
              label: 'Earnings'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}
