import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_envelope.dart';
import '../../../core/utils/formatters.dart';
import '../application/acara_providers.dart';
import '../data/acara_repository.dart';
import 'acara_screen.dart' show labelKehadiran;
import 'acara_voting_screen.dart';

/// Detail acara + konfirmasi kehadiran (RSVP), QR check-in, dan voting.
class AcaraDetailScreen extends ConsumerWidget {
  const AcaraDetailScreen({super.key, required this.kode});

  final String kode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(acaraDetailProvider(kode));
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Acara')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e is ApiException ? e.message : 'Acara tidak dapat dimuat.')),
        data: (d) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(acaraDetailProvider(kode)),
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Text(d.acara.nama, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (d.acara.tglMulai != null) _Baris(Icons.schedule, _rentang(d.acara)),
            if (d.acara.lokasi.isNotEmpty) _Baris(Icons.location_on_outlined, d.acara.lokasi),
            if (d.linkMaps != null) _Tautan('Buka peta', d.linkMaps!),
            if (d.acara.linkOnline != null) _Tautan('Tautan acara online', d.acara.linkOnline!),
            if (d.acara.batasRsvp != null)
              _Baris(Icons.event_busy_outlined, 'Batas konfirmasi: ${formatTanggal(d.acara.batasRsvp!)}'),
            if (d.acara.deskripsi.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(d.acara.deskripsi),
            ],
            if (d.deskripsiMateri.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(d.deskripsiMateri),
            ],
            const Divider(height: 32),
            _BlokKehadiran(detail: d, kode: kode),
            if (d.adaVoting) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => AcaraVotingScreen(kode: kode)),
                ),
                icon: const Icon(Icons.how_to_vote_outlined),
                label: const Text('Voting'),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  static String _rentang(Acara a) {
    final m = formatTanggal(a.tglMulai!);
    return a.tglSelesai == null ? m : '$m - ${formatTanggal(a.tglSelesai!)}';
  }
}

class _Baris extends StatelessWidget {
  const _Baris(this.icon, this.teks);
  final IconData icon;
  final String teks;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(child: Text(teks)),
        ]),
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

class _BlokKehadiran extends ConsumerWidget {
  const _BlokKehadiran({required this.detail, required this.kode});

  final DetailAcara detail;
  final String kode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = detail.peserta;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
      if (p != null && p.punyaQr) ...[
        const SizedBox(height: 12),
        _KartuQr(kode: kode),
      ],
    ]);
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
      error: (e, _) => const SizedBox.shrink(),
      data: (q) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            const Text('QR Check-in', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(8),
              child: QrImageView(data: q.token, size: 200),
            ),
            const SizedBox(height: 8),
            Text('Unit ${q.kodeUnit}'),
            if (q.sudahCheckin) const Text('Sudah check-in'),
          ]),
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
      final msg = await ref.read(acaraRepositoryProvider).rsvp(
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
      setState(() => _galat = e.message);
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
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                subtitle: Text(_berkas[f.key]?.split('/').last ?? (_sudahAda(f.key) ? 'Sudah diunggah' : 'Belum dipilih (PDF/JPG/PNG, maks 5 MB)')),
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
        ]),
      ),
    );
  }
}
