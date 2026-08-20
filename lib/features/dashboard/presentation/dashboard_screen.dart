import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../acara/presentation/acara_screen.dart';
import '../application/dashboard_providers.dart';

/// Beranda — piutang, info unit, meter air terakhir (Tier 1, lihat docs/96
/// §4). Layout mengikuti desain resmi: banner sambutan olive, lalu kartu
/// tagihan & pemakaian air, ditutup kartu info unit.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(dashboardSummaryProvider),
      child: CustomScrollView(
        slivers: [
          const SliverAppBar(
            title: Text('Beranda'),
            floating: true,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: summaryAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, _) => Padding(
                  padding: const EdgeInsets.only(top: 48),
                  child: Center(child: Text('Gagal memuat dashboard: $err')),
                ),
                data: (summary) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primaryOlive,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Selamat Datang di Portal Owner',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Unit ${summary.unitCode ?? '-'}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Ini adalah halaman informasi untuk owner',
                                  style: TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.apartment_rounded, color: Colors.white, size: 32),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const _PengumumanAcaraCard(),
                    const SizedBox(height: 12),
                    _InfoCard(
                      icon: Icons.credit_card_outlined,
                      iconColor: AppColors.invoiceBadgeFg,
                      label: 'Tagihan Belum Dibayar',
                      value: formatRupiah(summary.piutang),
                      linkLabel: 'Lihat Tagihan',
                    ),
                    const SizedBox(height: 12),
                    _InfoCard(
                      icon: Icons.water_drop_outlined,
                      iconColor: AppColors.blueAccent,
                      label: 'Pemakaian Air Bulan Ini',
                      value: summary.meterAirTerakhir != null
                          ? '${summary.meterAirTerakhir} M³'
                          : '-',
                      linkLabel: 'Lihat Riwayat',
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryOlive.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primaryOlive.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.home_work_outlined, color: AppColors.primaryOlive),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Unit ${summary.unitCode ?? '-'}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.bold)),
                                if (summary.namaPemilik != null)
                                  Text('Pemilik: ${summary.namaPemilik}'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ringkasan acara terdekat yang butuh konfirmasi kehadiran — reuse kartu
/// dari fitur Acara supaya tombol konfirmasi konsisten.
class _PengumumanAcaraCard extends ConsumerWidget {
  const _PengumumanAcaraCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton(
      style: TextButton.styleFrom(padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
      onPressed: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const AcaraScreen())),
      child: const Align(
        alignment: Alignment.centerLeft,
        child: Text('Lihat semua acara & pengumuman →'),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.linkLabel,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String linkLabel;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(linkLabel, style: const TextStyle(color: AppColors.primaryOlive)),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward, size: 14, color: AppColors.primaryOlive),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor),
            ),
          ],
        ),
      ),
    );
  }
}
