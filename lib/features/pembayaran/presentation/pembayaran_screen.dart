import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../application/pembayaran_providers.dart';

/// Riwayat pembayaran + bukti (kwitansi) — Tier 1 (lihat docs/96 §4).
class PembayaranScreen extends ConsumerWidget {
  const PembayaranScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final riwayatAsync = ref.watch(riwayatBayarProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Pembayaran')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(riwayatBayarProvider),
        child: riwayatAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Gagal memuat riwayat: $err')),
          data: (list) {
            if (list.isEmpty) {
              return ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.only(top: 64),
                    child: Center(child: Text('Belum ada riwayat pembayaran.')),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = list[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.receipt_long_outlined),
                    title: Text(formatRupiah(item.nominal)),
                    subtitle: Text(
                      '${item.metode} • ${item.tanggal != null ? formatTanggal(item.tanggal!) : '-'}',
                    ),
                    trailing: Text(item.status),
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
