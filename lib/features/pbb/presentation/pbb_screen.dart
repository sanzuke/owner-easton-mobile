import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_envelope.dart';
import '../../../core/theme/tampilan.dart';
import '../../../core/utils/formatters.dart';
import '../../dashboard/presentation/dash_palette.dart';
import '../application/pbb_providers.dart';
import '../data/pbb_repository.dart';

/// Tombol dalam Row kartu: tema app memberi tombol lebar penuh tinggi 52 dan font 16, yang di sini
/// terlalu besar (dan jadi lebar tak hingga di dalam Row), jadi dikecilkan.
const _gayaTombolBaris = ButtonStyle(
  minimumSize: WidgetStatePropertyAll(Size(0, 36)),
  padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 14)),
  textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
);

/// Pajak Bumi dan Bangunan: NOP, tagihan per tahun, SPPT (PDF dari admin) dan bukti bayar yang
/// diunggah owner. Setara halaman PBB di portal web owner (`GET /pbb`, docs/96b §9c).
class PbbScreen extends ConsumerWidget {
  const PbbScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pbbAsync = ref.watch(pbbProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('PBB')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(pbbProvider),
        child: pbbAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => ListView(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 64, 24, 0),
                child: Column(
                  children: [
                    const Text(
                      'Data PBB belum bisa dimuat. Periksa koneksi lalu coba lagi.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => ref.invalidate(pbbProvider),
                      child: const Text('Coba lagi'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          data: (pbb) {
            if (!pbb.tersedia) {
              return ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.fromLTRB(24, 64, 24, 0),
                    child: Center(
                      child: Text(
                        'Data PBB untuk unit Anda belum tersedia.\nSilakan hubungi manajemen Easton Park.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              );
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _KartuNop(nop: pbb.nop),
                const SizedBox(height: 16),
                if (pbb.items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 32),
                    child: Center(child: Text('Belum ada rincian tagihan PBB.')),
                  ),
                for (final item in pbb.items) ...[
                  _KartuTahun(item: item),
                  const SizedBox(height: 8),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _KartuNop extends StatelessWidget {
  const _KartuNop({required this.nop});

  final String? nop;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Card(
      color: cs.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.description_outlined, size: 36, color: cs.onPrimaryContainer),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('NOP (Nomor Objek Pajak)', style: text.bodyMedium?.copyWith(color: cs.onPrimaryContainer)),
                  const SizedBox(height: 2),
                  Text(
                    (nop == null || nop!.isEmpty) ? 'Belum diisi' : nop!,
                    style: text.titleLarge?.copyWith(color: cs.onPrimaryContainer, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KartuTahun extends ConsumerStatefulWidget {
  const _KartuTahun({required this.item});

  final PbbTahun item;

  @override
  ConsumerState<_KartuTahun> createState() => _KartuTahunState();
}

class _KartuTahunState extends ConsumerState<_KartuTahun> {
  static const _maksByte = 5 * 1024 * 1024;

  bool _sibuk = false;

  void _info(String pesan) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan)));
  }

  /// Jalankan aksi jaringan dengan kunci `_sibuk` supaya tidak terkirim ganda.
  Future<void> _jalankan(Future<void> Function() aksi) async {
    if (_sibuk) return;
    setState(() => _sibuk = true);
    try {
      await aksi();
    } on ApiException catch (e) {
      _info(e.message);
    } catch (_) {
      _info('Terjadi kesalahan. Periksa koneksi lalu coba lagi.');
    } finally {
      if (mounted) setState(() => _sibuk = false);
    }
  }

  Future<void> _buka(JenisBerkasPbb jenis) => _jalankan(() async {
        final uri = await ref.read(pbbRepositoryProvider).tautan(widget.item.idDetail, jenis);
        final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!ok) _info('Tidak ada aplikasi untuk membuka berkas ini.');
      });

  Future<void> _unggah() => _jalankan(() async {
        final r = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        );
        final path = r?.files.single.path;
        if (path == null) return;
        if (await File(path).length() > _maksByte) {
          _info('Ukuran file melebihi 5 MB.');
          return;
        }
        final pesan = await ref.read(pbbRepositoryProvider).uploadBukti(widget.item.idDetail, path);
        ref.invalidate(pbbProvider);
        _info(pesan.isEmpty ? 'Bukti bayar berhasil diunggah.' : pesan);
      });

  Future<void> _hapus() async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus bukti bayar'),
        content: Text('Hapus bukti bayar PBB tahun ${widget.item.tahun}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (yakin != true) return;
    await _jalankan(() async {
      final pesan = await ref.read(pbbRepositoryProvider).hapusBukti(widget.item.idDetail);
      ref.invalidate(pbbProvider);
      _info(pesan.isEmpty ? 'Bukti bayar dihapus.' : pesan);
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PBB ${item.tahun}', style: text.bodyLarge),
                      const SizedBox(height: 6),
                      _BadgeLunas(lunas: item.lunas),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (item.lunas)
                  Text('-', style: text.titleLarge?.copyWith(color: cs.onSurfaceVariant))
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Tagihan', style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      Text(
                        formatRupiah(item.tagihan),
                        style: text.titleLarge?.copyWith(color: cs.primary, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
              ],
            ),
            const Divider(height: 24),
            _BarisBerkas(
              label: 'SPPT',
              keterangan: item.adaPdf
                  ? (item.tglUploadPdf != null ? 'Diunggah ${formatTanggal(item.tglUploadPdf!)}' : 'Tersedia')
                  : 'Belum tersedia',
              aksi: item.adaPdf
                  ? [
                      OutlinedButton.icon(
                        style: _gayaTombolBaris,
                        onPressed: _sibuk ? null : () => _buka(JenisBerkasPbb.pdf),
                        icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                        label: const Text('Lihat'),
                      ),
                    ]
                  : const [],
            ),
            const SizedBox(height: 10),
            _BarisBerkas(
              label: 'Bukti bayar',
              keterangan: item.adaBukti
                  ? (item.tglUploadBukti != null
                      ? 'Diunggah ${formatTanggal(item.tglUploadBukti!)}'
                      : 'Sudah diunggah')
                  : 'Belum diunggah',
              aksi: item.adaBukti
                  ? [
                      OutlinedButton.icon(
                        style: _gayaTombolBaris,
                        onPressed: _sibuk ? null : () => _buka(JenisBerkasPbb.bukti),
                        icon: const Icon(Icons.visibility_outlined, size: 18),
                        label: const Text('Lihat'),
                      ),
                      IconButton(
                        tooltip: 'Ganti bukti',
                        onPressed: _sibuk ? null : _unggah,
                        icon: const Icon(Icons.autorenew_rounded),
                      ),
                      IconButton(
                        tooltip: 'Hapus bukti',
                        onPressed: _sibuk ? null : _hapus,
                        icon: Icon(Icons.delete_outline_rounded, color: cs.error),
                      ),
                    ]
                  : [
                      FilledButton.icon(
                        style: _gayaTombolBaris,
                        onPressed: _sibuk ? null : _unggah,
                        icon: const Icon(Icons.upload_rounded, size: 18),
                        label: const Text('Unggah'),
                      ),
                    ],
            ),
            if (_sibuk) const Padding(padding: EdgeInsets.only(top: 10), child: LinearProgressIndicator()),
          ],
        ),
      ),
    );
  }
}

class _BarisBerkas extends StatelessWidget {
  const _BarisBerkas({required this.label, required this.keterangan, required this.aksi});

  final String label;
  final String keterangan;
  final List<Widget> aksi;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              Text(keterangan, style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            ],
          ),
        ),
        ...aksi,
      ],
    );
  }
}

/// Lunas = hijau (palet yang sama dengan badge status tiket selesai), belum lunas = kuning.
class _BadgeLunas extends StatelessWidget {
  const _BadgeLunas({required this.lunas});

  final bool lunas;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final p = DashPalette.untuk(TampilanMode.nyaman, brightness);
    final aksen = lunas
        ? p.okText
        : (brightness == Brightness.dark ? const Color(0xFFE8C75A) : const Color(0xFF8A6A0A));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: aksen.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        lunas ? 'Lunas' : 'Belum Lunas',
        style: TextStyle(color: aksen, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
