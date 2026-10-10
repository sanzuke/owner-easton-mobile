import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/filter_periode.dart';
import '../application/pembayaran_providers.dart';

/// Riwayat pembayaran + bukti (kwitansi) — Tier 1 (lihat docs/96 §4). Infinite scroll (20 per halaman) dan
/// filter periode (tanggal pembayaran).
class PembayaranScreen extends ConsumerStatefulWidget {
  const PembayaranScreen({super.key});

  @override
  ConsumerState<PembayaranScreen> createState() => _PembayaranScreenState();
}

class _PembayaranScreenState extends ConsumerState<PembayaranScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.hasClients && _scroll.position.extentAfter < 300) {
        ref.read(riwayatBayarProvider.notifier).muatLagi();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final riwayatAsync = ref.watch(riwayatBayarProvider);
    final periode = ref.watch(periodePembayaranProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Pembayaran')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: FilterPeriode(
              periode: periode,
              onChanged: (p) =>
                  ref.read(periodePembayaranProvider.notifier).state = p,
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(riwayatBayarProvider),
              child: riwayatAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 64, 24, 0),
                      child: Column(
                        children: [
                          const Text(
                            'Riwayat pembayaran belum bisa dimuat. Periksa koneksi lalu tarik layar ke bawah untuk mencoba lagi.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () =>
                                ref.invalidate(riwayatBayarProvider),
                            child: const Text('Coba lagi'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                data: (daftar) {
                  if (daftar.items.isEmpty) {
                    return ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 64),
                          child: Center(
                            child: Text(
                              periode == null
                                  ? 'Belum ada riwayat pembayaran.'
                                  : 'Tidak ada pembayaran pada periode ini.',
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  return ListView.builder(
                    controller: _scroll,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: daftar.items.length + 1,
                    itemBuilder: (context, index) {
                      if (index == daftar.items.length) {
                        return PenutupDaftar(
                          state: daftar,
                          onCobaLagi: () => ref
                              .read(riwayatBayarProvider.notifier)
                              .muatLagi(),
                        );
                      }
                      final item = daftar.items[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Card(
                          margin: EdgeInsets.zero,
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
                            isThreeLine:
                                item.kwitansi.isNotEmpty ||
                                item.keterangan.isNotEmpty,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
