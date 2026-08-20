import 'package:flutter/material.dart';

import '../features/acara/presentation/acara_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/lainnya/presentation/lainnya_screen.dart';
import '../features/tagihan/presentation/tagihan_list_screen.dart';

/// Shell utama setelah login — bottom navigation 4 tab mengikuti desain
/// resmi: Beranda, Tagihan, Acara, Lainnya (Tiket/Profil/Pembayaran diakses
/// dari dalam Tagihan/Lainnya, bukan tab sendiri — lihat README).
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
    AcaraScreen(),
    LainnyaScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Beranda'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Tagihan'),
          NavigationDestination(icon: Icon(Icons.event_outlined), label: 'Acara'),
          NavigationDestination(icon: Icon(Icons.grid_view_outlined), label: 'Lainnya'),
        ],
      ),
    );
  }
}
