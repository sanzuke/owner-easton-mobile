import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_envelope.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/galat_view.dart';
import '../application/acara_providers.dart';
import '../application/pembuka_berkas.dart';
import '../data/acara_repository.dart';
import '../data/berkas_acara.dart';
import 'acara_screen.dart' show labelKehadiran;
import 'acara_voting_screen.dart';
import 'pratinjau_gambar_screen.dart';

/// Detail acara: banner, jadwal, dokumen (undangan/tata tertib/materi), konfirmasi kehadiran
/// (RSVP), QR check-in, dan voting. `GET /acara/{kode}` + `/banner` + `/dokumen/{tipe}` + `/qr`.
class AcaraDetailScreen extends ConsumerWidget {
  const AcaraDetailScreen({super.key, required this.kode});

  final String kode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(acaraDetailProvider(kode));
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Acara')),
      body: async.when(
        skipLoadingOnReload: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => RefreshIndicator(
          onRefresh: () => _muatUlang(ref),
          child: GalatView(
            error: e,
            fallback: 'Acara tidak dapat dimuat.',
            onCoba: () => ref.invalidate(acaraDetailProvider(kode)),
          ),
        ),
        data: (d) => RefreshIndicator(
          onRefresh: () => _muatUlang(ref),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              if (d.acara.adaBanner) ...[_Banner(kode: kode), const SizedBox(height: 16)],
              Text(d.acara.nama, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              if (d.acara.tglMulai != null) _Baris(Icons.schedule, _rentang(d.acara)),
              if (d.acara.lokasi.isNotEmpty) _Baris(Icons.location_on_outlined, d.acara.lokasi),
              if (d.linkMaps != null) _Tautan('Buka peta', d.linkMaps!),
              if (d.acara.linkOnline != null) _Tautan('Tautan acara online', d.acara.linkOnline!),
              if (d.acara.batasRsvp != null)
                _Baris(Icons.event_busy_outlined, 'Batas konfirmasi: ${formatTanggal(d.acara.batasRsvp!)}'),
              if (d.acara.deskripsi.isNotEmpty) ...[const SizedBox(height: 12), Text(d.acara.deskripsi)],
              if (d.deskripsiMateri.isNotEmpty) ...[const SizedBox(height: 12), Text(d.deskripsiMateri)],
              if (d.adaUndangan || d.adaTatib || d.adaMateri) ...[
                const Divider(height: 32),
                _BlokDokumen(kode: kode, detail: d),
              ],
              const Divider(height: 32),
              _BlokKehadiran(detail: d, kode: kode),
              if (d.adaVoting) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute<void>(builder: (_) => AcaraVotingScreen(kode: kode))),
                  icon: const Icon(Icons.how_to_vote_outlined),
                  label: const Text('Voting'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _muatUlang(WidgetRef ref) async {
    ref.invalidate(acaraDetailProvider(kode));
    try {
      await ref.read(acaraDetailProvider(kode).future);
    } catch (_) {
      // galat ditampilkan oleh state provider.
    }
  }

  static String _rentang(Acara a) {
    final m = formatTanggal(a.tglMulai!);
    return a.tglSelesai == null ? m : '$m - ${formatTanggal(a.tglSelesai!)}';
  }
}

/// Banner acara. Diunduh sebagai bytes karena endpoint butuh header Authorization.
class _Banner extends ConsumerWidget {
  const _Banner({required this.kode});

  final String kode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final async = ref.watch(acaraBannerProvider(kode));
    return async.when(
      loading: () => AspectRatio(
        aspectRatio: 16 / 9,
        child: DecoratedBox(
          decoration: BoxDecoration(color: cs.surfaceContainer, borderRadius: BorderRadius.circular(20)),
          child: const Center(child: CircularProgressIndicator()),
        ),
      ),
      // Banner hanya hiasan: bila gagal dimuat, detail acara tetap tampil tanpa banner.
      error: (e, _) => const SizedBox.shrink(),
      data: (bytes) => ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => PratinjauGambarScreen(judul: 'Banner', bytes: bytes),
            ),
          ),
          child: Image.memory(
            bytes,
            width: double.infinity,
            fit: BoxFit.fitWidth,
            errorBuilder: (context, error, stack) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

class _Baris extends StatelessWidget {
  const _Baris(this.icon, this.teks);
  final IconData icon;
  final String teks;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(child: Text(teks)),
      ],
    ),
  );
}

class _Tautan extends StatelessWidget {
  const _Tautan(this.label, this.url);
  final String label;
  final String url;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: TextButton.icon(
      onPressed: () async {
        final uri = Uri.tryParse(url);
        if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
      },
      icon: const Icon(Icons.open_in_new, size: 16),
      label: Text(label),
    ),
  );
}

/// Undangan / tata tertib / materi: diunduh lalu dibuka (gambar di pratinjau, PDF/Word di aplikasi pembaca).
class _BlokDokumen extends ConsumerStatefulWidget {
  const _BlokDokumen({required this.kode, required this.detail});

  final String kode;
  final DetailAcara detail;

  @override
  ConsumerState<_BlokDokumen> createState() => _BlokDokumenState();
}

class _BlokDokumenState extends ConsumerState<_BlokDokumen> {
  JenisDokumenAcara? _sibuk;

  bool _ada(JenisDokumenAcara t) => switch (t) {
    JenisDokumenAcara.undangan => widget.detail.adaUndangan,
    JenisDokumenAcara.tatib => widget.detail.adaTatib,
    JenisDokumenAcara.materi => widget.detail.adaMateri,
  };

  void _info(String pesan) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan)));
  }

  Future<void> _buka(JenisDokumenAcara tipe) async {
    if (_sibuk != null) return;
    setState(() => _sibuk = tipe);
    try {
      final bytes = await ref.read(acaraRepositoryProvider).getDokumen(widget.kode, tipe);
      if (!mounted) return;
      final jenis = deteksiBerkas(bytes);
      if (jenis.gambar) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => PratinjauGambarScreen(judul: tipe.label, bytes: bytes),
          ),
        );
      } else {
        final nama = '${tipe.label.replaceAll(' ', '')}-${widget.kode.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '')}';
        final ok = await ref.read(pembukaBerkasProvider).buka(bytes, nama: nama, jenis: jenis);
        if (!ok) _info('Tidak ada aplikasi di perangkat untuk membuka berkas ini.');
      }
    } on ApiException catch (e) {
      _info(
        e.statusCode == 404
            ? '${tipe.label} tidak tersedia.'
            : pesanGalat(e, fallback: '${tipe.label} tidak dapat dibuka.'),
      );
    } catch (_) {
      _info('${tipe.label} tidak dapat dibuka.');
    } finally {
      if (mounted) setState(() => _sibuk = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Dokumen', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              for (final t in JenisDokumenAcara.values)
                if (_ada(t))
                  ListTile(
                    key: ValueKey('dokumen-${t.name}'),
                    leading: const Icon(Icons.description_outlined),
                    title: Text(t.label),
                    trailing: _sibuk == t
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.open_in_new, size: 18),
                    enabled: _sibuk == null,
                    onTap: () => _buka(t),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BlokKehadiran extends ConsumerWidget {
  const _BlokKehadiran({required this.detail, required this.kode});

  final DetailAcara detail;
  final String kode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = detail.peserta;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Konfirmasi Kehadiran', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (p == null)
          const Text('Belum ada konfirmasi dari unit Anda.')
        else ...[
          Text('Status: ${labelKehadiran(p.kehadiran)}'),
          if (p.namaHadir.isNotEmpty) Text('Nama hadir: ${p.namaHadir}'),
          if (p.namaWakil.isNotEmpty) Text('Penerima kuasa: ${p.namaWakil}'),
          if (p.sudahCheckin) const Text('Sudah check-in.', style: TextStyle(fontWeight: FontWeight.w600)),
        ],
        const SizedBox(height: 12),
        if (detail.sudahCheckin)
          const Text('Kehadiran sudah tercatat; perubahan hanya oleh pengurus.')
        else if (detail.bisaRsvp)
          FilledButton.icon(
            onPressed: () async {
              final ok = await showModalBottomSheet<bool>(
                context: context,
                isScrollControlled: true,
                builder: (_) => FormRsvp(kode: kode, awal: p),
              );
              if (ok == true) {
                ref.invalidate(acaraDetailProvider(kode));
                ref.invalidate(acaraListProvider);
                ref.invalidate(acaraQrProvider(kode));
              }
            },
            icon: const Icon(Icons.event_available),
            label: Text(p == null ? 'Konfirmasi Kehadiran' : 'Ubah Konfirmasi'),
          )
        else
          const Text('Konfirmasi kehadiran sudah ditutup.'),
        if (p != null && p.punyaQr) ...[const SizedBox(height: 12), _KartuQr(kode: kode)],
      ],
    );
  }
}

class _KartuQr extends ConsumerWidget {
  const _KartuQr({required this.kode});
  final String kode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(acaraQrProvider(kode));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(pesanGalat(e, fallback: 'QR check-in belum bisa dimuat.'), textAlign: TextAlign.center),
              TextButton(onPressed: () => ref.invalidate(acaraQrProvider(kode)), child: const Text('Coba lagi')),
            ],
          ),
        ),
      ),
      data: (q) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text('QR Check-in', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              const Text('Tunjukkan kode ini kepada petugas di lokasi acara.', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(8),
                child: QrImageView(data: q.token, size: 200),
              ),
              const SizedBox(height: 8),
              Text('Unit ${q.kodeUnit}'),
              if (q.sudahCheckin) const Text('Sudah check-in'),
            ],
          ),
        ),
      ),
    );
  }
}

/// Formulir RSVP: online / offline (pemilik atau dikuasakan + 3 berkas).
class FormRsvp extends ConsumerStatefulWidget {
  const FormRsvp({super.key, required this.kode, this.awal});

  final String kode;
  final PesertaAcara? awal;

  @override
  ConsumerState<FormRsvp> createState() => _FormRsvpState();
}

class _FormRsvpState extends ConsumerState<FormRsvp> {
  late String _cara;
  late String _tipe;
  late final TextEditingController _namaHadir;
  late final TextEditingController _namaWakil;
  final Map<String, String> _berkas = {};
  bool _kirim = false;
  String? _galat;

  static const _field = {
    'surat_kuasa': 'Surat kuasa',
    'ktp_wakil': 'KTP penerima kuasa',
    'surat_izin_huni': 'Surat izin huni',
  };

  @override
  void initState() {
    super.initState();
    final a = widget.awal;
    _cara = a == null ? 'online' : (a.kehadiran == 'online' ? 'online' : 'offline');
    _tipe = a != null && a.kehadiran == 'dikuasakan' ? 'dikuasakan' : 'pemilik';
    _namaHadir = TextEditingController(text: a?.namaHadir ?? '');
    _namaWakil = TextEditingController(text: a?.namaWakil ?? '');
  }

  @override
  void dispose() {
    _namaHadir.dispose();
    _namaWakil.dispose();
    super.dispose();
  }

  bool _sudahAda(String f) => switch (f) {
    'surat_kuasa' => widget.awal?.adaSuratKuasa ?? false,
    'ktp_wakil' => widget.awal?.adaKtpWakil ?? false,
    _ => widget.awal?.adaSuratIzinHuni ?? false,
  };

  Future<void> _pilih(String f) async {
    final r = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png']);
    final path = r?.files.single.path;
    if (path != null) setState(() => _berkas[f] = path);
  }

  Future<void> _simpan() async {
    final dikuasakan = _cara == 'offline' && _tipe == 'dikuasakan';
    if (dikuasakan) {
      if (_namaWakil.text.trim().isEmpty) {
        setState(() => _galat = 'Nama penerima kuasa wajib diisi.');
        return;
      }
      for (final f in _field.keys) {
        if (!_berkas.containsKey(f) && !_sudahAda(f)) {
          setState(() => _galat = '${_field[f]} wajib diunggah.');
          return;
        }
      }
    }
    setState(() {
      _kirim = true;
      _galat = null;
    });
    try {
      final msg = await ref
          .read(acaraRepositoryProvider)
          .rsvp(
            widget.kode,
            cara: _cara,
            offlineTipe: _cara == 'offline' ? _tipe : null,
            namaHadir: _namaHadir.text.trim(),
            namaWakilKuasa: _namaWakil.text.trim(),
            berkas: dikuasakan ? _berkas : const {},
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _galat = pesanGalat(e, fallback: 'Konfirmasi gagal disimpan.'));
    } catch (_) {
      if (mounted) setState(() => _galat = 'Konfirmasi gagal disimpan. Periksa berkas dan koneksi lalu coba lagi.');
    } finally {
      if (mounted) setState(() => _kirim = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dikuasakan = _cara == 'offline' && _tipe == 'dikuasakan';
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Konfirmasi Kehadiran', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'online', label: Text('Online')),
                ButtonSegment(value: 'offline', label: Text('Offline')),
              ],
              selected: {_cara},
              onSelectionChanged: (s) => setState(() => _cara = s.first),
            ),
            if (_cara == 'offline') ...[
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'pemilik', label: Text('Pemilik')),
                  ButtonSegment(value: 'dikuasakan', label: Text('Dikuasakan')),
                ],
                selected: {_tipe},
                onSelectionChanged: (s) => setState(() => _tipe = s.first),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _namaHadir,
              decoration: const InputDecoration(labelText: 'Nama yang hadir', border: OutlineInputBorder()),
            ),
            if (dikuasakan) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _namaWakil,
                decoration: const InputDecoration(labelText: 'Nama penerima kuasa', border: OutlineInputBorder()),
              ),
              for (final f in _field.entries)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(f.value),
                  subtitle: Text(
                    _berkas[f.key]?.split('/').last ??
                        (_sudahAda(f.key) ? 'Sudah diunggah' : 'Belum dipilih (PDF/JPG/PNG, maks 5 MB)'),
                  ),
                  trailing: TextButton(onPressed: () => _pilih(f.key), child: const Text('Pilih')),
                ),
            ],
            if (_galat != null) ...[
              const SizedBox(height: 8),
              Text(_galat!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _kirim ? null : _simpan,
                child: _kirim
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Simpan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
