import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../../dashboard/presentation/dash_palette.dart';
import '../application/p3srs_providers.dart';
import '../data/p3srs_repository.dart';
import 'artikel_detail_screen.dart';
import 'artikel_list_screen.dart';

/// Bagian "Berita Terbaru" di beranda: kartu geser ke samping berisi berita situs publik
/// eprjatinangor.com (`GET /berita`). Disembunyikan sepenuhnya saat memuat, gagal, atau kosong —
/// beranda tidak boleh terganggu oleh berita.
class BeritaBeranda extends ConsumerWidget {
  const BeritaBeranda({super.key, required this.p});

  final DashPalette p;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final berita = ref.watch(beritaTerbaruProvider).valueOrNull;
    if (berita == null || berita.isEmpty) return const SizedBox.shrink();

    // Tinggi kartu ikut skala teks supaya tidak meluap saat font diperbesar (mode Nyaman untuk usia lanjut).
    final skala = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.6);
    final tinggi = (p.modern ? 258.0 : 288.0) * skala;
    final lebar = p.modern ? 224.0 : 252.0;

    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Text(
                    'BERITA TERBARU',
                    style: TextStyle(
                      color: p.modern ? p.inkSoft : p.inkFaint,
                      fontSize: p.modern ? 11 : 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: p.modern ? 1.0 : 0.6,
                    ),
                  ),
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: p.primary,
                  textStyle: TextStyle(fontSize: p.modern ? 12 : 14, fontWeight: FontWeight.w800),
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ArtikelListScreen(judul: 'Berita', sumber: SumberArtikel.berita),
                  ),
                ),
                child: const Text('Lihat semua'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Beranda memberi padding samping; daftar dilebarkan sampai tepi layar supaya kartu tidak
          // terpotong di dalam padding dan terlihat bisa digeser.
          SizedBox(
            height: tinggi,
            child: LayoutBuilder(
              builder: (context, c) {
                final pad = p.modern ? 16.0 : 20.0;
                final lebarLayar = c.maxWidth + 2 * pad;
                return OverflowBox(
                  minWidth: lebarLayar,
                  maxWidth: lebarLayar,
                  child: SizedBox(
                    width: lebarLayar,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: pad),
                      itemCount: berita.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 12),
                      itemBuilder: (context, i) => _KartuBerita(berita: berita[i], p: p, lebar: lebar),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _KartuBerita extends StatelessWidget {
  const _KartuBerita({required this.berita, required this.p, required this.lebar});

  final ArtikelRingkas berita;
  final DashPalette p;
  final double lebar;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(p.modern ? 14 : 20);
    return SizedBox(
      width: lebar,
      child: Material(
        color: p.surface,
        shape: RoundedRectangleBorder(borderRadius: radius, side: BorderSide(color: p.border)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ArtikelDetailScreen(id: berita.id, sumber: SumberArtikel.berita)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: berita.thumbUrl == null
                    ? _Placeholder(p: p)
                    : Image.network(
                        berita.thumbUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => _Placeholder(p: p),
                      ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(12, p.modern ? 10 : 12, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (berita.kategori.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: p.primaryTint, borderRadius: BorderRadius.circular(100)),
                          child: Text(
                            berita.kategori,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: p.primary, fontSize: p.modern ? 10.5 : 12, fontWeight: FontWeight.w800),
                          ),
                        ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: Text(
                          berita.judul,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: p.ink,
                            fontSize: p.modern ? 13 : 15,
                            height: 1.3,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (berita.tanggal != null)
                        Text(
                          formatTanggal(berita.tanggal!),
                          style: TextStyle(color: p.inkSoft, fontSize: p.modern ? 11 : 12.5),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.p});

  final DashPalette p;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: p.surfaceTonal,
        child: Center(child: Icon(Icons.newspaper_rounded, size: 34, color: p.primary.withValues(alpha: 0.6))),
      );
}
