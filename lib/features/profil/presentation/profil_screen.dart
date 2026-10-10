import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_envelope.dart';
import '../../../core/utils/formatters.dart';
import '../../auth/application/auth_providers.dart';
import '../../dashboard/application/dashboard_providers.dart';
import '../application/profil_providers.dart';
import '../data/profil_repository.dart';

/// Tombol dalam baris kartu: tema app memberi tombol lebar penuh tinggi 52 (jadi lebar tak hingga di Row).
const _gayaTombolKecil = ButtonStyle(
  minimumSize: WidgetStatePropertyAll(Size(0, 36)),
  padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 14)),
  textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
);

/// Profil pemilik: foto, data pribadi, dokumen identitas (KTP/KK), dan edit data kontak.
class ProfilScreen extends ConsumerStatefulWidget {
  const ProfilScreen({super.key});

  @override
  ConsumerState<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends ConsumerState<ProfilScreen> {
  static const _maksByte = 5 * 1024 * 1024;

  bool _editing = false;
  bool _saving = false;
  bool _sibuk = false;
  final _namaController = TextEditingController();
  final _hpController = TextEditingController();
  final _emailController = TextEditingController();
  final _alamatController = TextEditingController();

  @override
  void dispose() {
    _namaController.dispose();
    _hpController.dispose();
    _emailController.dispose();
    _alamatController.dispose();
    super.dispose();
  }

  void _info(String pesan) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan)));
  }

  void _startEdit(Profil profil) {
    _namaController.text = profil.nama;
    _hpController.text = profil.hp;
    _emailController.text = profil.email ?? '';
    _alamatController.text = profil.alamat ?? '';
    setState(() => _editing = true);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(profilRepositoryProvider).updateProfil(
            nama: _namaController.text.trim(),
            hp: _hpController.text.trim(),
            email: _emailController.text.trim(),
            alamat: _alamatController.text.trim(),
          );
      ref.invalidate(profilProvider);
      if (mounted) setState(() => _editing = false);
      _info('Profil berhasil diperbarui.');
    } on ApiException catch (e) {
      _info(e.message);
    } catch (_) {
      _info('Terjadi kesalahan. Periksa koneksi lalu coba lagi.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Pilih file lalu unggah; satu aksi unggah berjalan pada satu waktu.
  Future<void> _unggah({
    required List<String> ekstensi,
    required Future<void> Function(String path) kirim,
    required String sukses,
  }) async {
    if (_sibuk) return;
    setState(() => _sibuk = true);
    try {
      final r = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ekstensi);
      final path = r?.files.single.path;
      if (path == null) return;
      if (await File(path).length() > _maksByte) {
        _info('Ukuran file melebihi 5 MB.');
        return;
      }
      await kirim(path);
      ref.invalidate(profilProvider);
      _info(sukses);
    } on ApiException catch (e) {
      _info(e.message);
    } catch (_) {
      _info('Terjadi kesalahan. Periksa koneksi lalu coba lagi.');
    } finally {
      if (mounted) setState(() => _sibuk = false);
    }
  }

  Future<void> _gantiFoto() => _unggah(
        ekstensi: const ['jpg', 'jpeg', 'png'],
        kirim: ref.read(profilRepositoryProvider).uploadFoto,
        sukses: 'Foto profil berhasil diperbarui.',
      );

  Future<void> _unggahBerkas(String jenis, String nama) => _unggah(
        ekstensi: const ['jpg', 'jpeg', 'png', 'pdf'],
        kirim: (path) => ref.read(profilRepositoryProvider).uploadBerkas(jenis: jenis, filePath: path),
        sukses: '$nama berhasil diunggah.',
      );

  Future<void> _logout() async {
    await ref.read(authRepositoryProvider).logout();
    ref.invalidate(authStateProvider);
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final profilAsync = ref.watch(profilProvider);
    final unit = ref.watch(dashboardSummaryProvider).valueOrNull?.unitCode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(tooltip: 'Keluar', onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: profilAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 64, 24, 0),
              child: Column(
                children: [
                  const Text('Profil belum bisa dimuat. Periksa koneksi lalu coba lagi.', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: () => ref.invalidate(profilProvider), child: const Text('Coba lagi')),
                ],
              ),
            ),
          ],
        ),
        data: (profil) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(profilProvider),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              if (_sibuk) const LinearProgressIndicator(),
              _Kepala(profil: profil, unit: unit, onGantiFoto: _sibuk ? null : _gantiFoto),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _editing ? _formEdit() : _tampilan(profil),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tampilan(Profil profil) {
    final lahir = [
      if ((profil.tempatLahir ?? '').trim().isNotEmpty) profil.tempatLahir!.trim(),
      if (profil.tanggalLahir != null) formatTanggalPanjang(profil.tanggalLahir!),
    ].join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _JudulBagian('Informasi Pribadi'),
        Card(
          child: Column(
            children: [
              _BarisInfo(ikon: Icons.phone_iphone_rounded, label: 'No. HP', nilai: profil.hp),
              _BarisInfo(ikon: Icons.mail_outline_rounded, label: 'Email', nilai: profil.email),
              _BarisInfo(ikon: Icons.home_outlined, label: 'Alamat', nilai: profil.alamat),
              _BarisInfo(ikon: Icons.cake_outlined, label: 'Tempat, tanggal lahir', nilai: lahir),
              _BarisInfo(ikon: Icons.person_outline_rounded, label: 'Jenis kelamin', nilai: _jenisKelamin(profil.jenisKelamin), terakhir: true),
            ],
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          onPressed: () => _startEdit(profil),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Edit Profil'),
        ),
        const SizedBox(height: 20),
        const _JudulBagian('Dokumen Identitas'),
        Card(
          child: Column(
            children: [
              _BarisDokumen(
                ikon: Icons.badge_outlined,
                nama: 'KTP',
                berkas: profil.ktp,
                onUnggah: _sibuk ? null : () => _unggahBerkas('ktp', 'KTP'),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _BarisDokumen(
                ikon: Icons.family_restroom_outlined,
                nama: 'Kartu Keluarga',
                berkas: profil.kartuKeluarga,
                onUnggah: _sibuk ? null : () => _unggahBerkas('kk', 'Kartu Keluarga'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Format JPG, PNG, atau PDF, maksimal 5 MB. Mengunggah ulang menggantikan berkas sebelumnya.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _formEdit() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _JudulBagian('Edit Profil'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(controller: _namaController, decoration: const InputDecoration(labelText: 'Nama')),
                const SizedBox(height: 12),
                TextField(
                  controller: _hpController,
                  decoration: const InputDecoration(labelText: 'No. HP'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _alamatController,
                  decoration: const InputDecoration(labelText: 'Alamat'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Dua tombol dibuat identik (tinggi, bentuk, huruf) — tema hanya mengatur tombol terisi,
        // sehingga tombol garis tepi tampil lebih kecil bila tidak disamakan.
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: _tombolSetara,
                onPressed: _saving ? null : () => setState(() => _editing = false),
                child: const Text('Batal'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                style: _tombolSetara,
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Simpan'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static final _tombolSetara = ButtonStyle(
    minimumSize: const WidgetStatePropertyAll(Size.fromHeight(52)),
    shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
    textStyle: const WidgetStatePropertyAll(TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
  );

  static String? _jenisKelamin(String? v) {
    final j = (v ?? '').trim().toLowerCase();
    if (j.isEmpty) return null;
    if (j.startsWith('l') || j == 'pria') return 'Laki-laki';
    if (j.startsWith('p') || j == 'wanita') return 'Perempuan';
    return v;
  }
}

/// Kepala profil: latar gradasi lembut, foto bulat dengan tombol kamera, nama, dan unit.
class _Kepala extends StatelessWidget {
  const _Kepala({required this.profil, required this.unit, required this.onGantiFoto});

  final Profil profil;
  final String? unit;
  final VoidCallback? onGantiFoto;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final adaFoto = profil.fotoUrl != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [cs.primaryContainer, cs.surface],
        ),
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(shape: BoxShape.circle, color: cs.surface, border: Border.all(color: cs.primary, width: 2)),
                child: CircleAvatar(
                  radius: 52,
                  backgroundColor: cs.surfaceContainerHigh,
                  backgroundImage: adaFoto ? NetworkImage(profil.fotoUrl!) : null,
                  // Foto gagal dimuat -> tetap tampil ikon, bukan kotak kosong.
                  onBackgroundImageError: adaFoto ? (_, _) {} : null,
                  child: adaFoto ? null : Icon(Icons.person_rounded, size: 52, color: cs.onSurfaceVariant),
                ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Material(
                  color: cs.primary,
                  shape: const CircleBorder(side: BorderSide(color: Colors.white, width: 2)),
                  child: IconButton(
                    tooltip: adaFoto ? 'Ganti foto' : 'Tambah foto',
                    constraints: const BoxConstraints.tightFor(width: 36, height: 36),
                    padding: EdgeInsets.zero,
                    iconSize: 18,
                    color: cs.onPrimary,
                    onPressed: onGantiFoto,
                    icon: const Icon(Icons.photo_camera_rounded),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(profil.nama, textAlign: TextAlign.center, style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          if (unit != null && unit!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(100)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.home_work_outlined, size: 15, color: cs.primary),
                  const SizedBox(width: 6),
                  Text('Unit $unit', style: text.bodySmall?.copyWith(color: cs.primary, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _JudulBagian extends StatelessWidget {
  const _JudulBagian(this.teks);

  final String teks;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
        child: Text(teks, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
      );
}

class _BarisInfo extends StatelessWidget {
  const _BarisInfo({required this.ikon, required this.label, required this.nilai, this.terakhir = false});

  final IconData ikon;
  final String label;
  final String? nilai;
  final bool terakhir;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final kosong = nilai == null || nilai!.trim().isEmpty;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(10)),
                child: Icon(ikon, size: 20, color: cs.onPrimaryContainer),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                    const SizedBox(height: 2),
                    Text(
                      kosong ? '-' : nilai!.trim(),
                      style: text.bodyLarge?.copyWith(color: kosong ? cs.onSurfaceVariant : null),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!terakhir) const Divider(height: 1, indent: 66, endIndent: 16),
      ],
    );
  }
}

class _BarisDokumen extends StatelessWidget {
  const _BarisDokumen({required this.ikon, required this.nama, required this.berkas, required this.onUnggah});

  final IconData ikon;
  final String nama;
  final BerkasProfil? berkas;
  final VoidCallback? onUnggah;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final ada = berkas != null;
    final status = !ada
        ? 'Belum diunggah'
        : (berkas!.diunggahPada != null ? 'Diunggah ${formatTanggal(berkas!.diunggahPada!)}' : 'Sudah diunggah');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(10)),
            child: Icon(ikon, size: 20, color: cs.onPrimaryContainer),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nama, style: text.bodyLarge),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      ada ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                      size: 14,
                      color: ada ? Colors.green.shade600 : cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Flexible(child: Text(status, style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ada
              ? OutlinedButton(style: _gayaTombolKecil, onPressed: onUnggah, child: const Text('Ganti'))
              : FilledButton(style: _gayaTombolKecil, onPressed: onUnggah, child: const Text('Unggah')),
        ],
      ),
    );
  }
}
