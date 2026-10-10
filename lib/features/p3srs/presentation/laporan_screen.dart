import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../application/p3srs_providers.dart';
import 'html_konten.dart';

/// Laporan In/Out P3SRS per bulan — isi HTML yang sama dengan portal web owner (kategori Laporan).
/// Bulan yang belum disetujui bendahara & ketua tampil "Laporan belum tersedia", seperti di web.
class LaporanScreen extends ConsumerStatefulWidget {
  const LaporanScreen({super.key, required this.judul});

  final String judul;

  @override
  ConsumerState<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends ConsumerState<LaporanScreen> {
  late DateTime _bulan = DateTime(DateTime.now().year, DateTime.now().month);

  String get _kode => DateFormat('yyyy-MM').format(_bulan);

  bool get _bulanIni {
    final n = DateTime.now();
    return _bulan.year == n.year && _bulan.month == n.month;
  }

  void _geser(int delta) => setState(() => _bulan = DateTime(_bulan.year, _bulan.month + delta));

  @override
  Widget build(BuildContext context) {
    final laporanAsync = ref.watch(p3srsLaporanProvider(_kode));
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(widget.judul)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Bulan sebelumnya',
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: () => _geser(-1),
                ),
                Expanded(
                  child: Text(
                    DateFormat('MMMM y', 'id_ID').format(_bulan),
                    textAlign: TextAlign.center,
                    style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  tooltip: 'Bulan berikutnya',
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: _bulanIni ? null : () => _geser(1),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(p3srsLaporanProvider(_kode)),
              child: laporanAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => _Pesan(
                  teks: 'Laporan belum bisa dimuat. Periksa koneksi lalu coba lagi.',
                  tombol: FilledButton(
                    onPressed: () => ref.invalidate(p3srsLaporanProvider(_kode)),
                    child: const Text('Coba lagi'),
                  ),
                ),
                data: (lap) {
                  if (!lap.tersedia || lap.html == null) {
                    return const _Pesan(teks: 'Laporan belum tersedia untuk bulan ini.');
                  }
                  return ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      // Tabel laporan punya 4-5 kolom: minimal 640 lebar agar tak terpotong, gulir ke samping di HP sempit.
                      LayoutBuilder(
                        builder: (context, c) => SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: c.maxWidth < 640 ? 640 : c.maxWidth,
                            child: HtmlKonten(lap.html!),
                          ),
                        ),
                      ),
                      if (lap.pengunjung != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.person_outline, size: 16, color: cs.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text('${lap.pengunjung} unit membaca', style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                          ],
                        ),
                      ],
                    ],
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

class _Pesan extends StatelessWidget {
  const _Pesan({required this.teks, this.tombol});

  final String teks;
  final Widget? tombol;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 64, 24, 0),
          child: Column(
            children: [
              Text(teks, textAlign: TextAlign.center),
              if (tombol != null) ...[const SizedBox(height: 12), tombol!],
            ],
          ),
        ),
      ],
    );
  }
}
