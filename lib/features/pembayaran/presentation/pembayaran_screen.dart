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
          error: (err, _) => ListView(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 64, 24, 0),
                child: Column(
                  children: [
                    const Text('Riwayat pembayaran belum bisa dimuat. Periksa koneksi lalu tarik layar ke bawah untuk mencoba lagi.',
                        textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => ref.invalidate(riwayatBayarProvider),
                      child: const Text('Coba lagi'),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
                    title: Text(formatRupiah(item.jumlah)),
                    subtitle: Text(
                      [
                        '${item.metode} • ${item.tanggal != null ? formatTanggal(item.tanggal!) : '-'}',
                        if (item.kwitansi.isNotEmpty) item.kwitansi,
                        if (item.keterangan.isNotEmpty) item.keterangan,
                      ].join('\n'),
                    ),
                    isThreeLine: item.kwitansi.isNotEmpty || item.keterangan.isNotEmpty,
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
