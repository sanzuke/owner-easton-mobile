import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tampilan.dart';
import '../application/dashboard_providers.dart';
import '../application/tampilan_providers.dart';
import 'dash_palette.dart';

/// Pengaturan > Tampilan: Otomatis (menurut usia di data pemilik), Nyaman, atau Modern.
/// Pilihan manual disimpan di perangkat dan mengalahkan default usia.
class TampilanScreen extends ConsumerStatefulWidget {
  const TampilanScreen({super.key});

  @override
  ConsumerState<TampilanScreen> createState() => _TampilanScreenState();
}

class _TampilanScreenState extends ConsumerState<TampilanScreen> {
  TampilanPilihan? _dipilih;
  TemaPilihan? _tema;
  bool _menyimpan = false;

  Future<void> _simpan(TampilanPilihan pilihan, TemaPilihan tema) async {
    setState(() => _menyimpan = true);
    await ref.read(tampilanPilihanProvider.notifier).simpan(pilihan);
    await ref.read(temaPilihanProvider.notifier).simpan(tema);
    if (!mounted) return;
    setState(() => _menyimpan = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengaturan tampilan disimpan.')));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final tersimpan = ref.watch(tampilanPilihanProvider).valueOrNull ?? TampilanPilihan.otomatis;
    final pilihan = _dipilih ?? tersimpan;
    final temaTersimpan = ref.watch(temaPilihanProvider).valueOrNull ?? TemaPilihan.sistem;
    final tema = _tema ?? temaTersimpan;
    final lahir = ref.watch(dashboardSummaryProvider).valueOrNull?.tanggalLahir;
    final sekarang = ref.watch(sekarangProvider);
    final usia = hitungUsia(lahir, sekarang);
    final hasilOtomatis = modeOtomatis(lahir, sekarang);
    final p = DashPalette.untuk(TampilanMode.nyaman, Theme.of(context).brightness);

    final tagOtomatis = usia == null
        ? 'Terpilih · usia belum terdata → Nyaman'
        : 'Terpilih · usia $usia tahun → ${hasilOtomatis == TampilanMode.nyaman ? 'Nyaman' : 'Modern'}';

    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        backgroundColor: p.bg,
        foregroundColor: p.ink,
        title: const Text('Pengaturan Akun'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
        children: [
          Text('Tampilan Aplikasi', style: TextStyle(color: p.ink, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            'Tema warna berlaku untuk seluruh aplikasi.',
            style: TextStyle(color: p.inkSoft, fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 16),
          _Opsi(
            p: p,
            terpilih: tema == TemaPilihan.sistem,
            judul: 'Ikuti HP',
            deskripsi: 'Terang atau gelap mengikuti pengaturan HP.',
            onTap: () => setState(() => _tema = TemaPilihan.sistem),
          ),
          _Opsi(
            p: p,
            terpilih: tema == TemaPilihan.terang,
            judul: 'Terang',
            deskripsi: 'Latar terang, nyaman dibaca di tempat terang.',
            onTap: () => setState(() => _tema = TemaPilihan.terang),
          ),
          _Opsi(
            p: p,
            terpilih: tema == TemaPilihan.gelap,
            judul: 'Gelap',
            deskripsi: 'Latar gelap, lebih hemat mata dan baterai di tempat redup.',
            onTap: () => setState(() => _tema = TemaPilihan.gelap),
          ),
          const SizedBox(height: 18),
          Text('Gaya Tampilan', style: TextStyle(color: p.ink, fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            'Pilih gaya tampilan yang paling nyaman untuk Bapak/Ibu gunakan sehari-hari.',
            style: TextStyle(color: p.inkSoft, fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 16),
          _Opsi(
            p: p,
            terpilih: pilihan == TampilanPilihan.otomatis,
            judul: 'Otomatis',
            deskripsi: 'Mengikuti usia yang terdaftar pada data pemilik.',
            tag: pilihan == TampilanPilihan.otomatis ? tagOtomatis : null,
            onTap: () => setState(() => _dipilih = TampilanPilihan.otomatis),
          ),
          _Opsi(
            p: p,
            terpilih: pilihan == TampilanPilihan.nyaman,
            judul: 'Nyaman',
            deskripsi: 'Teks & tombol lebih besar, tampilan lebih lega. Cocok untuk memudahkan membaca.',
            onTap: () => setState(() => _dipilih = TampilanPilihan.nyaman),
          ),
          _Opsi(
            p: p,
            terpilih: pilihan == TampilanPilihan.modern,
            judul: 'Modern',
            deskripsi: 'Tampilan lebih ringkas dan kekinian, warna lebih berani.',
            onTap: () => setState(() => _dipilih = TampilanPilihan.modern),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: p.surfaceTonal, borderRadius: BorderRadius.circular(16)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 20, color: p.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Pilihan ini hanya mengubah tampilan — semua informasi unit, tagihan, dan cara membayar tetap sama.',
                    style: TextStyle(color: p.inkSoft, fontSize: 13, height: 1.55),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 56,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: p.primary,
                foregroundColor: p.onHeader,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              onPressed: _menyimpan ? null : () => _simpan(pilihan, tema),
              child: const Text('Simpan Pengaturan'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Opsi extends StatelessWidget {
  const _Opsi({
    required this.p,
    required this.terpilih,
    required this.judul,
    required this.deskripsi,
    required this.onTap,
    this.tag,
  });

  final DashPalette p;
  final bool terpilih;
  final String judul;
  final String deskripsi;
  final String? tag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        button: true,
        selected: terpilih,
        label: judul,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: terpilih ? p.primaryTint : null,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: terpilih ? p.primary : p.border, width: 2),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: terpilih ? p.primary : p.border, width: 2),
                  ),
                  child: terpilih
                      ? Center(child: Container(width: 12, height: 12, decoration: BoxDecoration(color: p.primary, shape: BoxShape.circle)))
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(judul, style: TextStyle(color: p.ink, fontSize: 16.5, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(deskripsi, style: TextStyle(color: p.inkSoft, fontSize: 13.5, height: 1.5)),
                      if (tag != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(color: p.surfaceTonal, borderRadius: BorderRadius.circular(100)),
                          child: Text(
                            tag!.toUpperCase(),
                            style: TextStyle(color: p.primary, fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 0.3),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
