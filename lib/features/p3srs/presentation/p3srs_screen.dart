import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/p3srs_providers.dart';
import 'artikel_list_screen.dart';
import 'laporan_screen.dart';

/// Menu P3SRS: daftar kategori dari CMS (kategori laporan membuka laporan bulanan, lainnya daftar
/// artikel) + semua artikel. Setara menu P3SRS di portal web owner (docs/96b §9d).
class P3srsScreen extends ConsumerWidget {
  const P3srsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kategoriAsync = ref.watch(p3srsKategoriProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('P3SRS')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(p3srsKategoriProvider),
        child: kategoriAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => ListView(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 64, 24, 0),
                child: Column(
                  children: [
                    const Text(
                      'Data P3SRS belum bisa dimuat. Periksa koneksi lalu coba lagi.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => ref.invalidate(p3srsKategoriProvider),
                      child: const Text('Coba lagi'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          data: (kategori) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _BarisMenu(
                ikon: Icons.article_outlined,
                judul: 'Semua artikel',
                subjudul: 'Pengumuman dan informasi terbaru',
                onTap: () => _buka(context, const ArtikelListScreen(judul: 'Semua artikel')),
              ),
              for (final k in kategori) ...[
                const SizedBox(height: 8),
                _BarisMenu(
                  ikon: k.laporan ? Icons.bar_chart_rounded : Icons.folder_open_outlined,
                  judul: k.nama,
                  subjudul: k.laporan ? 'Laporan pemasukan & pengeluaran bulanan' : '${k.total} artikel',
                  onTap: () => _buka(
                    context,
                    k.laporan ? LaporanScreen(judul: k.nama) : ArtikelListScreen(judul: k.nama, kategori: k),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _buka(BuildContext context, Widget layar) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => layar));
}

class _BarisMenu extends StatelessWidget {
  const _BarisMenu({required this.ikon, required this.judul, required this.subjudul, required this.onTap});

  final IconData ikon;
  final String judul;
  final String subjudul;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cs.primaryContainer,
          child: Icon(ikon, color: cs.onPrimaryContainer),
        ),
        title: Text(judul),
        subtitle: Text(subjudul),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
