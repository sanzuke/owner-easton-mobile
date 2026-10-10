import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../application/tiket_providers.dart';
import '../data/tiket_repository.dart';
import 'tiket_status.dart';

/// Detail tiket: timeline status + lampiran (docs/96b §9). [tiket] = baris dari daftar, dipakai
/// untuk nama tipe karena `GET /tiket/{id}` tidak membawanya.
class TiketDetailScreen extends ConsumerWidget {
  const TiketDetailScreen({super.key, required this.tiket});

  final Tiket tiket;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(tiketDetailProvider(tiket.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Tiket')),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Gagal memuat detail: $err')),
        data: (detail) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(detail.keterangan, style: Theme.of(context).textTheme.titleMedium),
                        ),
                        const SizedBox(width: 8),
                        TiketStatusBadge(status: detail.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('${detail.noForm} · ${tiket.tipe}'),
                    if (detail.tanggal != null) Text(formatTanggal(detail.tanggal!)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Riwayat', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            if (detail.timeline.isEmpty) const Text('Belum ada riwayat.'),
            for (var i = 0; i < detail.timeline.length; i++)
              _TimelineItem(
                item: detail.timeline[i],
                pertama: i == 0,
                terakhir: i == detail.timeline.length - 1,
              ),
            if (detail.berkas.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Lampiran', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              ...detail.berkas.map((b) => ListTile(
                    leading: const Icon(Icons.attach_file),
                    title: Text(b.nama),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

/// Satu titik timeline: titik + garis vertikal di kiri, keterangan dan waktu di kanan.
/// Titik terakhir (status terkini) diisi warna utama; yang sebelumnya hanya garis tepi.
class _TimelineItem extends StatelessWidget {
  const _TimelineItem({required this.item, required this.pertama, required this.terakhir});

  final TiketTimeline item;
  final bool pertama;
  final bool terakhir;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final garis = cs.outlineVariant;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                SizedBox(
                  height: 6,
                  child: pertama ? null : VerticalDivider(width: 2, thickness: 2, color: garis),
                ),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: terakhir ? cs.primary : cs.surface,
                    border: Border.all(color: terakhir ? cs.primary : cs.outline, width: 2),
                  ),
                ),
                Expanded(
                  child: terakhir ? const SizedBox.shrink() : VerticalDivider(width: 2, thickness: 2, color: garis),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.keterangan,
                    style: text.bodyMedium?.copyWith(
                      fontWeight: terakhir ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  if (item.tanggal != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        item.adaJam ? formatTanggalWaktu(item.tanggal!) : formatTanggal(item.tanggal!),
                        style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
