import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tampilan.dart';
import '../../dashboard/presentation/dash_palette.dart';
import '../application/tiket_providers.dart';
import '../data/tiket_repository.dart';
import 'tiket_detail_screen.dart';
import 'tiket_create_screen.dart';

/// Daftar tiket + tombol ajukan tiket baru — Tier 1 (lihat docs/96 §4).
/// Dipanggil dari grid kategori [RequestScreen] dengan [tipe] untuk
/// menampilkan tiket 1 tipe saja (persis alur desain resmi); tanpa tipe,
/// menampilkan semua tiket.
class TiketListScreen extends ConsumerWidget {
  const TiketListScreen({super.key, this.tipe});

  final TiketTipe? tipe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(tiketListProvider);
    final filtered = listAsync.whenData(
      (list) => tipe == null ? list : list.where((t) => t.tipe == tipe!.nama).toList(),
    );

    return Scaffold(
      appBar: AppBar(title: Text(tipe?.nama ?? 'Tiket')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => TiketCreateScreen(tipeAwal: tipe?.id)),
          );
          if (created == true) {
            ref.invalidate(tiketListProvider);
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Ajukan Tiket'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(tiketListProvider),
        child: filtered.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Gagal memuat tiket: $err')),
          data: (list) {
            if (list.isEmpty) {
              return ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.only(top: 64),
                    child: Center(child: Text('Belum ada tiket.')),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: list.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final tiket = list[index];
                final gaya = _GayaStatus.dari(tiket.status, Theme.of(context).brightness);
                return Card(
                  clipBehavior: Clip.antiAlias,
                  color: gaya.kartu,
                  child: InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TiketDetailScreen(tiket: tiket),
                      ),
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(width: 5, color: gaya.aksen),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tiket.keterangan,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context).textTheme.titleSmall,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${tiket.noForm} · ${tiket.tipe}',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _StatusBadge(status: tiket.status, gaya: gaya),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Tiga kelompok status supaya mana yang belum selesai langsung terlihat:
/// baru (kuning), diproses (biru), selesai/ditutup (hijau). Ditolak merah.
class _GayaStatus {
  const _GayaStatus({required this.kartu, required this.aksen});

  final Color kartu;
  final Color aksen;

  static _GayaStatus dari(String status, Brightness kecerahan) {
    final gelap = kecerahan == Brightness.dark;
    final p = DashPalette.untuk(TampilanMode.nyaman, kecerahan);
    switch (status) {
      case 'Ditutup':
      case 'Selesai':
        return _GayaStatus(kartu: p.okBg, aksen: p.okText);
      case 'Ditolak':
        return _GayaStatus(kartu: p.warnBg, aksen: p.warnText);
      case 'Diproses':
      case 'Menunggu Pembayaran':
        return gelap
            ? const _GayaStatus(kartu: Color(0xFF1B2A3D), aksen: Color(0xFF8DB6E8))
            : const _GayaStatus(kartu: Color(0xFFE3EEFB), aksen: Color(0xFF2F69A8));
      default: // Draft, Open = permintaan baru
        return gelap
            ? const _GayaStatus(kartu: Color(0xFF3A3316), aksen: Color(0xFFE8C75A))
            : const _GayaStatus(kartu: Color(0xFFFFF3D1), aksen: Color(0xFF8A6A0A));
    }
  }
}

/// Badge status tiket di kanan atas card, warnanya mengikuti kelompok status.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.gaya});

  final String status;
  final _GayaStatus gaya;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: gaya.aksen.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        status,
        style: TextStyle(color: gaya.aksen, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
