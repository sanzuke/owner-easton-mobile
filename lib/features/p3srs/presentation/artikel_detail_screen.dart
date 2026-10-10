import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../application/p3srs_providers.dart';
import 'html_konten.dart';

/// Detail artikel P3SRS: banner, judul, tanggal, dan isi HTML dari CMS.
class ArtikelDetailScreen extends ConsumerWidget {
  const ArtikelDetailScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(p3srsDetailProvider(id));
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Artikel')),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 64, 24, 0),
              child: Column(
                children: [
                  const Text('Artikel belum bisa dimuat. Periksa koneksi lalu coba lagi.', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: () => ref.invalidate(p3srsDetailProvider(id)), child: const Text('Coba lagi')),
                ],
              ),
            ),
          ],
        ),
        data: (a) {
          final meta = [
            if (a.kategori.isNotEmpty) a.kategori,
            if (a.tanggal != null) formatTanggalPanjang(a.tanggal!),
            if (a.pengunjung != null) '${a.pengunjung} pembaca',
          ].join(' · ');
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              if (a.bannerUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    a.bannerUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => const SizedBox.shrink(),
                  ),
                ),
              const SizedBox(height: 16),
              Text(a.judul, style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              if (meta.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(meta, style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              ],
              const SizedBox(height: 16),
              HtmlKonten(a.body),
            ],
          );
        },
      ),
    );
  }
}
