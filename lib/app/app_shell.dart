import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/tampilan.dart';
import '../features/acara/presentation/acara_screen.dart';
import '../features/dashboard/application/tampilan_providers.dart';
import '../features/dashboard/presentation/dash_palette.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/lainnya/presentation/lainnya_screen.dart';
import '../features/tagihan/presentation/tagihan_list_screen.dart';
import 'shell_provider.dart';

/// Shell utama setelah login — bottom navigation 4 tab: Beranda, Tagihan, Acara, Lainnya
/// (Tiket/Profil/Pembayaran diakses dari dalam Tagihan/Lainnya/Beranda, bukan tab sendiri).
/// Pada tema Modern, bar bawah di Beranda ikut gelap seperti prototipe desain.
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  static const _pages = [
    DashboardScreen(),
    TagihanListScreen(),
    AcaraScreen(),
    LainnyaScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(shellTabProvider);
    final modern = index == 0 && ref.watch(tampilanModeProvider) == TampilanMode.modern;
    const p = DashPalette.modernGelap;

    final bar = NavigationBar(
      selectedIndex: index,
      onDestinationSelected: (i) => ref.read(shellTabProvider.notifier).state = i,
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Beranda'),
        NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Tagihan'),
        NavigationDestination(icon: Icon(Icons.event_outlined), label: 'Acara'),
        NavigationDestination(icon: Icon(Icons.grid_view_outlined), label: 'Lainnya'),
      ],
    );

    return Scaffold(
      body: IndexedStack(index: index, children: _pages),
      bottomNavigationBar: modern
          ? NavigationBarTheme(
              data: NavigationBarThemeData(
                backgroundColor: p.surface,
                indicatorColor: p.primary.withValues(alpha: 0.18),
                iconTheme: WidgetStateProperty.resolveWith((s) =>
                    IconThemeData(color: s.contains(WidgetState.selected) ? p.primary : p.inkSoft)),
                labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: s.contains(WidgetState.selected) ? p.primary : p.inkSoft,
                    )),
              ),
              child: bar,
            )
          : bar,
    );
  }
}
