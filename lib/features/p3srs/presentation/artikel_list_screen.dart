import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_envelope.dart';
import '../../../core/utils/formatters.dart';
import '../application/p3srs_providers.dart';
import '../data/p3srs_repository.dart';
import 'artikel_detail_screen.dart';

/// Daftar artikel P3SRS (semua atau satu kategori) atau berita, dengan pencarian dan "Muat lagi" berhalaman.
class ArtikelListScreen extends ConsumerStatefulWidget {
  const ArtikelListScreen({super.key, required this.judul, this.kategori, this.sumber = SumberArtikel.p3srs});

  final String judul;
  final KategoriP3srs? kategori;
  final SumberArtikel sumber;

  @override
  ConsumerState<ArtikelListScreen> createState() => _ArtikelListScreenState();
}

class _ArtikelListScreenState extends ConsumerState<ArtikelListScreen> {
  final _cari = TextEditingController();
  final _items = <ArtikelRingkas>[];
  int _halaman = 0;
  bool _adaBerikutnya = false;
  bool _memuat = false;
  String? _galat;
  String _kataKunci = '';

  @override
  void initState() {
    super.initState();
    _muat(ulang: true);
  }

  @override
  void dispose() {
    _cari.dispose();
    super.dispose();
  }

  /// [ulang] = mulai dari halaman 1 (pencarian baru / tarik-segarkan); selain itu tambah halaman berikutnya.
  Future<void> _muat({bool ulang = false}) async {
    if (_memuat) return;
    setState(() {
      _memuat = true;
      _galat = null;
    });
    final kata = _kataKunci;
    try {
      final h = await ref.read(p3srsRepositoryProvider).getArtikel(
            sumber: widget.sumber,
            kategori: widget.kategori?.id,
            q: kata,
            halaman: ulang ? 1 : _halaman + 1,
          );
      if (!mounted || kata != _kataKunci) return;
      setState(() {
        if (ulang) _items.clear();
        _items.addAll(h.items);
        _halaman = h.halaman;
        _adaBerikutnya = h.adaBerikutnya;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _galat = e.message);
    } catch (_) {
      if (mounted) setState(() => _galat = 'Artikel belum bisa dimuat. Periksa koneksi lalu coba lagi.');
    } finally {
      if (mounted) setState(() => _memuat = false);
    }
  }

  void _cariBaru(String kata) {
    _kataKunci = kata.trim();
    _muat(ulang: true);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(widget.judul)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _cari,
              textInputAction: TextInputAction.search,
              onSubmitted: _cariBaru,
              decoration: InputDecoration(
                hintText: 'Cari artikel',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _kataKunci.isEmpty && _cari.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Hapus pencarian',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _cari.clear();
                          _cariBaru('');
                        },
                      ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _muat(ulang: true),
              child: _items.isEmpty ? _kosong(cs) : _daftar(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kosong(ColorScheme cs) {
    if (_memuat) return const Center(child: CircularProgressIndicator());
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 0),
          child: Column(
            children: [
              Text(
                _galat ?? (_kataKunci.isEmpty ? 'Belum ada artikel.' : 'Artikel tidak ditemukan.'),
                textAlign: TextAlign.center,
                style: TextStyle(color: _galat != null ? cs.error : null),
              ),
              if (_galat != null) ...[
                const SizedBox(height: 12),
                FilledButton(onPressed: () => _muat(ulang: true), child: const Text('Coba lagi')),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _daftar() {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: _items.length + 1,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        if (i < _items.length) return _KartuArtikel(artikel: _items[i], sumber: widget.sumber);
        if (_memuat) {
          return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
        }
        if (_galat != null) {
          return Center(child: TextButton(onPressed: _muat, child: Text('$_galat Coba lagi')));
        }
        return _adaBerikutnya
            ? Center(child: OutlinedButton(onPressed: _muat, child: const Text('Muat lagi')))
            : const SizedBox.shrink();
      },
    );
  }
}

class _KartuArtikel extends StatelessWidget {
  const _KartuArtikel({required this.artikel, required this.sumber});

  final ArtikelRingkas artikel;
  final SumberArtikel sumber;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final meta = [
      if (artikel.kategori.isNotEmpty) artikel.kategori,
      if (artikel.tanggal != null) formatTanggal(artikel.tanggal!),
    ].join(' · ');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ArtikelDetailScreen(id: artikel.id, sumber: sumber)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 76,
                  height: 76,
                  child: artikel.thumbUrl == null
                      ? ColoredBox(color: cs.surfaceContainerHigh, child: Icon(Icons.image_outlined, color: cs.onSurfaceVariant))
                      : Image.network(
                          artikel.thumbUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) => ColoredBox(
                            color: cs.surfaceContainerHigh,
                            child: Icon(Icons.image_not_supported_outlined, color: cs.onSurfaceVariant),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(artikel.judul, maxLines: 3, overflow: TextOverflow.ellipsis, style: text.bodyLarge),
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(meta, style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
