import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_envelope.dart';
import '../../../core/widgets/galat_view.dart';
import '../application/acara_providers.dart';
import '../data/acara_repository.dart';

/// Daftar voting satu acara; 1 unit = 1 suara per voting (aturan backend).
class AcaraVotingScreen extends ConsumerWidget {
  const AcaraVotingScreen({super.key, required this.kode});

  final String kode;

  Future<void> _muatUlang(WidgetRef ref) async {
    ref.invalidate(acaraVotingProvider(kode));
    try {
      await ref.read(acaraVotingProvider(kode).future);
    } catch (_) {
      // galat ditampilkan oleh state provider.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(acaraVotingProvider(kode));
    return Scaffold(
      appBar: AppBar(title: const Text('Voting')),
      body: async.when(
        skipLoadingOnReload: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => RefreshIndicator(
          onRefresh: () => _muatUlang(ref),
          child: GalatView(
            error: e,
            fallback: 'Voting tidak dapat dimuat.',
            onCoba: () => ref.invalidate(acaraVotingProvider(kode)),
          ),
        ),
        data: (d) {
          RefreshIndicator bungkus(Widget child) => RefreshIndicator(onRefresh: () => _muatUlang(ref), child: child);
          if (!d.sudahRsvp) {
            return bungkus(
              const KosongView(
                pesan: 'Konfirmasi kehadiran terlebih dahulu untuk ikut voting.',
                ikon: Icons.how_to_vote_outlined,
              ),
            );
          }
          if (d.votings.isEmpty) {
            return bungkus(const KosongView(pesan: 'Belum ada voting.', ikon: Icons.how_to_vote_outlined));
          }
          return bungkus(
            ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [for (final v in d.votings) KartuVoting(key: ValueKey(v.id), voting: v, kode: kode)],
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
  bool _muatHasil = false;
  HasilVoting? _hasil;

  Voting get v => widget.voting;

  void _info(String pesan) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan)));
  }

  Future<void> _suara() async {
    setState(() => _kirim = true);
    try {
      final msg = await ref.read(acaraRepositoryProvider).kirimSuara(v.id, _dipilih.toList());
      ref.invalidate(acaraVotingProvider(widget.kode));
      _info(msg);
    } on ApiException catch (e) {
      _info(pesanGalat(e, fallback: 'Suara gagal dikirim.'));
    } catch (_) {
      _info('Suara gagal dikirim. Coba lagi.');
    } finally {
      if (mounted) setState(() => _kirim = false);
    }
  }

  Future<void> _lihatHasil() async {
    if (_hasil != null) {
      setState(() => _hasil = null);
      return;
    }
    setState(() => _muatHasil = true);
    try {
      final h = await ref.read(acaraRepositoryProvider).getHasil(v.id);
      if (mounted) setState(() => _hasil = h);
    } on ApiException catch (e) {
      _info(pesanGalat(e, fallback: 'Hasil voting tidak dapat dimuat.'));
    } catch (_) {
      _info('Hasil voting tidak dapat dimuat.');
    } finally {
      if (mounted) setState(() => _muatHasil = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bisaPilih = v.buka && !v.sudah;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(v.pertanyaan, style: Theme.of(context).textTheme.titleMedium),
            if (!v.buka && v.labelTutup != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('${v.labelTutup}${v.alasanTutup == null ? '' : ': ${v.alasanTutup}'}'),
              ),
            if (v.multi && bisaPilih)
              const Padding(padding: EdgeInsets.only(top: 4), child: Text('Boleh memilih lebih dari satu.')),
            const SizedBox(height: 8),
            for (final o in v.opsi)
              if (v.multi)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(o.teks),
                  value: _dipilih.contains(o.id),
                  onChanged: bisaPilih
                      ? (x) => setState(() => x == true ? _dipilih.add(o.id) : _dipilih.remove(o.id))
                      : null,
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
            // Wrap, bukan Row: FilledButton di tema app berlebar tak hingga (minimumSize.fromHeight)
            // dan akan melempar "infinite width" bila ditaruh dalam Row.
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (bisaPilih)
                  FilledButton(
                    style: const ButtonStyle(minimumSize: WidgetStatePropertyAll(Size(0, 44))),
                    onPressed: _kirim || _dipilih.isEmpty ? null : _suara,
                    child: _kirim
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Kirim Suara'),
                  ),
                if (v.tampilHasil)
                  TextButton(
                    onPressed: _muatHasil ? null : _lihatHasil,
                    child: Text(_hasil == null ? 'Lihat Hasil' : 'Sembunyikan Hasil'),
                  ),
              ],
            ),
            if (_hasil != null) ...[const SizedBox(height: 8), HasilBar(hasil: _hasil!)],
          ],
        ),
      ),
    );
  }
}

/// Hasil voting: satu batang per opsi dengan jumlah suara dan persentase terhadap jumlah pemilih.
class HasilBar extends StatelessWidget {
  const HasilBar({super.key, required this.hasil});

  final HasilVoting hasil;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pemilih: ${hasil.pemilih} unit', style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        for (final o in hasil.opsi)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(o.teks)),
                    const SizedBox(width: 8),
                    Text('${o.jml} (${(hasil.bagian(o.jml) * 100).round()}%)'),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: hasil.bagian(o.jml),
                    minHeight: 8,
                    backgroundColor: cs.surfaceContainer,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
