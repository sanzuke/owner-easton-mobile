import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../application/p3srs_providers.dart';
import '../data/p3srs_repository.dart';
import 'artikel_list_screen.dart';
import 'laporan_screen.dart';

/// Menu P3SRS: daftar kategori dari CMS (kategori laporan membuka laporan bulanan, lainnya daftar
/// artikel) + semua artikel. Setara menu P3SRS di portal web owner (docs/96b §9d).
///
/// API baru mengirim `kelompok` per kategori → tampil dua bagian ("Informasi & Laporan" lalu
/// "Dokumen Legalitas & Lainnya") dengan kartu informatif. Server lama (tanpa `kelompok`) tetap
/// tampil sebagai daftar datar seperti sebelumnya. Urutan selalu mengikuti urutan dari server.
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
              if (kategori.any((k) => k.kelompok != null))
                ..._bagian(context, kategori)
              else
                for (final k in kategori) ...[
                  const SizedBox(height: 8),
                  _BarisMenu(
                    ikon: k.laporan ? Icons.bar_chart_rounded : Icons.folder_open_outlined,
                    judul: k.nama,
                    subjudul: k.laporan ? 'Laporan pemasukan & pengeluaran bulanan' : '${k.total} artikel',
                    onTap: () => _bukaKategori(context, k),
                  ),
                ],
            ],
          ),
        ),
      ),
    );
  }

  /// Dua bagian berurutan; kategori tanpa `kelompok` di respons campuran masuk bagian dokumen.
  List<Widget> _bagian(BuildContext context, List<KategoriP3srs> kategori) {
    final utama = kategori.where((k) => k.kelompok == KelompokP3srs.utama).toList(growable: false);
    final dokumen = kategori.where((k) => k.kelompok != KelompokP3srs.utama).toList(growable: false);
    return [
      for (final (judul, daftar) in [
        ('Informasi & Laporan', utama),
        ('Dokumen Legalitas & Lainnya', dokumen),
      ])
        if (daftar.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 24, 4, 4),
            child: Text(
              judul,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          for (final k in daftar) ...[
            const SizedBox(height: 8),
            _KartuKategori(kategori: k, onTap: () => _bukaKategori(context, k)),
          ],
        ],
    ];
  }

  void _bukaKategori(BuildContext context, KategoriP3srs k) => _buka(
        context,
        k.laporan ? LaporanScreen(judul: k.nama) : ArtikelListScreen(judul: k.nama, kategori: k),
      );

  void _buka(BuildContext context, Widget layar) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => layar));
}

/// Kata `ikon` dari API → ikon Material; kata tak dikenal/kosong jatuh ke ikon sesuai jenis kategori.
IconData ikonKategoriP3srs(KategoriP3srs k) => switch (k.ikon) {
      'info' => Icons.info_outline_rounded,
      'kegiatan' => Icons.event_note_outlined,
      'keuangan' => Icons.account_balance_wallet_outlined,
      'kalender' => Icons.calendar_month_outlined,
      'audit' => Icons.fact_check_outlined,
      'dokumen' => Icons.description_outlined,
      _ => k.laporan ? Icons.bar_chart_rounded : Icons.folder_open_outlined,
    };

class _KartuKategori extends StatelessWidget {
  const _KartuKategori({required this.kategori, required this.onTap});

  final KategoriP3srs kategori;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = kategori;
    final tema = Theme.of(context);
    final cs = tema.colorScheme;

    // Kategori laporan tidak punya artikel: hanya deskripsi (tanpa jumlah/terakhir diperbarui).
    final info = <String>[
      if (!k.laporan) k.total > 0 ? '${k.total} dokumen' : 'Belum ada dokumen',
      if (!k.laporan && k.terakhir != null) 'Terakhir diperbarui ${formatTanggalIso(k.terakhir)}',
    ];

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: cs.primaryContainer,
                child: Icon(ikonKategoriP3srs(k), color: cs.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(k.nama, style: tema.textTheme.titleMedium),
                    if (k.deskripsi != null) ...[
                      const SizedBox(height: 2),
                      Text(k.deskripsi!, style: tema.textTheme.bodyMedium),
                    ],
                    if (info.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        info.join(' · '),
                        style: tema.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
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
