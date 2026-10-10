import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/formatters.dart';
import '../application/utility_providers.dart';
import '../data/utility_repository.dart';

/// Utility > Pemakaian Air: meter terakhir, tarif, dan riwayat bulanan per tahun
/// (`GET /utility/air`, docs/96b §9b).
class UtilityScreen extends ConsumerWidget {
  const UtilityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final airAsync = ref.watch(utilityAirProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pemakaian Air')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(utilityAirProvider),
        child: airAsync.when(
          // Saat ganti tahun, tampilkan data lama dulu alih-alih layar kosong berputar.
          skipLoadingOnRefresh: true,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => ListView(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 64, 24, 0),
                child: Column(
                  children: [
                    const Text(
                      'Data pemakaian air belum bisa dimuat. Periksa koneksi lalu coba lagi.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => ref.invalidate(utilityAirProvider),
                      child: const Text('Coba lagi'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          data: (air) {
            if (air.tahun == null) {
              return ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.fromLTRB(24, 64, 24, 0),
                    child: Center(
                      child: Text(
                        'Belum ada catatan meter air untuk unit Anda.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              );
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _Ringkasan(air: air),
                const SizedBox(height: 16),
                if (air.tahunTersedia.length > 1) ...[
                  _PilihTahun(
                    tahun: air.tahun!,
                    tersedia: air.tahunTersedia,
                    onPilih: (t) => ref.read(utilityTahunProvider.notifier).state = t,
                  ),
                  const SizedBox(height: 12),
                ],
                if (air.items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 32),
                    child: Center(child: Text('Belum ada catatan meter di tahun ini.')),
                  ),
                for (final item in air.items) ...[
                  _KartuBulan(item: item),
                  const SizedBox(height: 8),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

String _angka(num v) => NumberFormat('#,##0.##', 'id_ID').format(v);

class _Ringkasan extends StatelessWidget {
  const _Ringkasan({required this.air});

  final UtilityAir air;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Card(
      color: cs.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.water_drop_outlined, size: 36, color: cs.onPrimaryContainer),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Meter terakhir', style: text.bodyMedium?.copyWith(color: cs.onPrimaryContainer)),
                  Text(
                    air.meterTerakhir == null ? '-' : '${_angka(air.meterTerakhir!)} m³',
                    style: text.headlineSmall?.copyWith(
                      color: cs.onPrimaryContainer,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tarif ${formatRupiah(air.tarifPerM3)} / m³',
                    style: text.bodySmall?.copyWith(color: cs.onPrimaryContainer),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PilihTahun extends StatelessWidget {
  const _PilihTahun({required this.tahun, required this.tersedia, required this.onPilih});

  final int tahun;
  final List<int> tersedia;
  final ValueChanged<int> onPilih;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tersedia.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) => ChoiceChip(
          label: Text('${tersedia[i]}'),
          selected: tersedia[i] == tahun,
          onSelected: (_) => onPilih(tersedia[i]),
        ),
      ),
    );
  }
}

class _KartuBulan extends StatelessWidget {
  const _KartuBulan({required this.item});

  final PemakaianAir item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final bulan = DateFormat('MMMM y', 'id_ID').format(DateTime(item.tahun, item.bulan.clamp(1, 12)));
    final ditagih = item.tagihan != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(bulan, style: text.bodyLarge),
                  const SizedBox(height: 4),
                  Text(
                    'Meter ${_angka(item.meterAwal)} → ${_angka(item.meterAkhir)}',
                    style: text.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Pemakaian ${_angka(item.pakai)} m³',
                    style: text.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (ditagih) ...[
                  Text('Tagihan', style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  Text(
                    formatRupiah(item.tagihan!),
                    style: text.titleLarge?.copyWith(color: cs.primary, fontWeight: FontWeight.w800),
                  ),
                ] else
                  Text('Belum ditagihkan', style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
