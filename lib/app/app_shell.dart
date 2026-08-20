import 'package:flutter/material.dart';

import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/pembayaran/presentation/pembayaran_screen.dart';
import '../features/profil/presentation/profil_screen.dart';
import '../features/tagihan/presentation/tagihan_list_screen.dart';
import '../features/tiket/presentation/tiket_list_screen.dart';

/// Shell utama setelah login — bottom navigation ke 5 fitur Tier 1
/// (lihat docs/96 §4): Dashboard, Tagihan, Tiket, Pembayaran, Profil.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _pages = [
    DashboardScreen(),
    TagihanListScreen(),
    TiketListScreen(),
    PembayaranScreen(),
    ProfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.receipt_outlined), label: 'Tagihan'),
          NavigationDestination(icon: Icon(Icons.confirmation_num_outlined), label: 'Tiket'),
          NavigationDestination(icon: Icon(Icons.payments_outlined), label: 'Bayar'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
      ),
    );
  }
}
