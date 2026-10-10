import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_envelope.dart';
import '../application/acara_providers.dart';
import '../data/acara_repository.dart';

/// Daftar voting satu acara; 1 unit = 1 suara per voting (aturan backend).
class AcaraVotingScreen extends ConsumerWidget {
  const AcaraVotingScreen({super.key, required this.kode});

  final String kode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(acaraVotingProvider(kode));
    return Scaffold(
      appBar: AppBar(title: const Text('Voting')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e is ApiException ? e.message : 'Voting tidak dapat dimuat.')),
        data: (d) {
          if (!d.sudahRsvp) {
            return const Center(
              child: Padding(padding: EdgeInsets.all(24), child: Text('Konfirmasi kehadiran terlebih dahulu untuk ikut voting.')),
            );
          }
          if (d.votings.isEmpty) return const Center(child: Text('Belum ada voting.'));
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(acaraVotingProvider(kode)),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [for (final v in d.votings) KartuVoting(voting: v, kode: kode)],
            ),
          );
        },
      ),
    );
  }
}

class KartuVoting extends ConsumerStatefulWidget {
  const KartuVoting({super.key, required this.voting, required this.kode});

  final Voting voting;
  final String kode;

  @override
  ConsumerState<KartuVoting> createState() => _KartuVotingState();
}

class _KartuVotingState extends ConsumerState<KartuVoting> {
  late final Set<int> _dipilih = {...widget.voting.pilihan};
  bool _kirim = false;
  HasilVoting? _hasil;

  Voting get v => widget.voting;

  Future<void> _suara() async {
    setState(() => _kirim = true);
    try {
      final msg = await ref.read(acaraRepositoryProvider).kirimSuara(v.id, _dipilih.toList());
      ref.invalidate(acaraVotingProvider(widget.kode));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _kirim = false);
    }
  }

  Future<void> _lihatHasil() async {
    try {
      final h = await ref.read(acaraRepositoryProvider).getHasil(v.id);
      if (mounted) setState(() => _hasil = h);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bisaPilih = v.buka && !v.sudah;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(v.pertanyaan, style: Theme.of(context).textTheme.titleMedium),
          if (!v.buka && v.labelTutup != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('${v.labelTutup}${v.alasanTutup == null ? '' : ': ${v.alasanTutup}'}'),
            ),
          const SizedBox(height: 8),
          for (final o in v.opsi)
            if (v.multi)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(o.teks),
                value: _dipilih.contains(o.id),
                onChanged: bisaPilih ? (x) => setState(() => x == true ? _dipilih.add(o.id) : _dipilih.remove(o.id)) : null,
              )
            else
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(_dipilih.contains(o.id) ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                title: Text(o.teks),
                enabled: bisaPilih,
                onTap: bisaPilih
                    ? () => setState(() {
                          _dipilih
                            ..clear()
                            ..add(o.id);
                        })
                    : null,
              ),
          if (v.sudah) const Text('Suara Anda sudah tersimpan.', style: TextStyle(fontWeight: FontWeight.w600)),
          Row(children: [
            if (bisaPilih)
              FilledButton(onPressed: _kirim || _dipilih.isEmpty ? null : _suara, child: const Text('Kirim Suara')),
            if (v.tampilHasil) TextButton(onPressed: _lihatHasil, child: const Text('Lihat Hasil')),
          ]),
          if (_hasil != null) ...[
            const SizedBox(height: 8),
            Text('Pemilih: ${_hasil!.pemilih} unit'),
            for (final o in _hasil!.opsi) Text('${o.teks}: ${o.jml}'),
          ],
        ]),
      ),
    );
  }
}
