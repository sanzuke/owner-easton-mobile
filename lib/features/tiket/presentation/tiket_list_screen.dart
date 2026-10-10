import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/tiket_providers.dart';
import '../data/tiket_repository.dart';
import 'tiket_detail_screen.dart';
import 'tiket_create_screen.dart';
import 'tiket_status.dart';

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
                final gaya = GayaStatusTiket.dari(tiket.status, Theme.of(context).brightness);
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
                                          style: Theme.of(context).textTheme.bodyLarge,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${tiket.noForm} · ${tiket.tipe}',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  TiketStatusBadge(status: tiket.status),
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
