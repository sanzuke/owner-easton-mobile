import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../acara/application/acara_providers.dart';
import '../../acara/presentation/acara_screen.dart';
import '../application/dashboard_providers.dart';

/// Beranda — piutang, info unit, meter air terakhir (Tier 1, lihat docs/96
/// §4). Layout mengikuti desain resmi persis: banner sambutan olive, kartu
/// pengumuman acara terdekat, kartu tagihan & pemakaian air, kartu info unit.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(dashboardSummaryProvider);
        ref.invalidate(acaraListProvider);
      },
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          summaryAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.only(top: 120),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.only(top: 120, left: 16, right: 16),
              child: Center(child: Text('Gagal memuat dashboard: $err')),
            ),
            data: (summary) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Banner sambutan — kartu lembut berwarna primaryContainer
                // (bukan blok warna penuh), supaya tidak mencolok.
                SafeArea(
                  bottom: false,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selamat datang',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Unit ${summary.unitCode ?? '-'}',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Portal informasi owner Easton Park',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer
                                      .withValues(alpha: 0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(Icons.apartment_rounded,
                              color: Theme.of(context).colorScheme.primary, size: 28),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _PengumumanAcaraCard(),
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
                          color: AppColors.primaryOlive.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: AppColors.primaryOlive.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                  if (summary.namaPemilik != null) ...[
                                    const SizedBox(height: 2),
                                    Text('Pemilik: ${summary.namaPemilik}'),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu pengumuman acara terdekat yang butuh konfirmasi kehadiran — bg
/// biru-ungu muda, tombol "Konfirmasi Kehadiran" navy, sesuai desain resmi.
/// Kalau tidak ada acara yang butuh konfirmasi, kartu ini tersembunyi.
class _PengumumanAcaraCard extends ConsumerWidget {
  const _PengumumanAcaraCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final acaraAsync = ref.watch(acaraListProvider);

    return acaraAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (err, _) => const SizedBox.shrink(),
      data: (list) {
        final acara = list.where((a) => a.butuhKonfirmasi && !a.sudahKonfirmasi).firstOrNull;
        if (acara == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.campaign_outlined, size: 16, color: Colors.indigo.shade400),
                    const SizedBox(width: 6),
                    Text(
                      'Pengumuman Acara',
                      style: TextStyle(
                        color: Colors.indigo.shade400,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(acara.judul,
                    style:
                        Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                if (acara.tanggal != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(formatTanggal(acara.tanggal!), style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
                if (acara.lokasi != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(child: Text(acara.lokasi!, style: const TextStyle(fontSize: 12))),
                    ],
                  ),
                ],
                if (acara.batasKonfirmasi != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Batas konfirmasi: ${formatTanggal(acara.batasKonfirmasi!)}',
                    style: const TextStyle(
                        color: AppColors.destructive, fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: AppColors.navyAccent),
                    onPressed: () => Navigator.of(context)
                        .push(MaterialPageRoute(builder: (_) => const AcaraScreen())),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Konfirmasi Kehadiran'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
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
      ),
    );
  }
}
