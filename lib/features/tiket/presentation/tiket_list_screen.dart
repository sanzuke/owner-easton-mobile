import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
                return Card(
                  child: ListTile(
                    title: Text(tiket.keterangan, maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: Text('${tiket.noForm} · ${tiket.tipe}'),
                    trailing: Chip(label: Text(tiket.status)),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TiketDetailScreen(tiket: tiket),
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
