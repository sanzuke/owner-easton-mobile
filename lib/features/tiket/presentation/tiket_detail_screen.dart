import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../application/tiket_providers.dart';

/// Detail tiket: histori + lampiran (lihat docs/96 update 19 Agustus).
class TiketDetailScreen extends ConsumerWidget {
  const TiketDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(tiketDetailProvider(id));

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Tiket')),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Gagal memuat detail: $err')),
        data: (detail) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(detail.judul, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text('Tipe: ${detail.tipe}'),
                    Text('Status: ${detail.status}'),
                    if (detail.tanggal != null) Text(formatTanggal(detail.tanggal!)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Histori', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            if (detail.histori.isEmpty) const Text('Belum ada histori.'),
            ...detail.histori.map(
              (h) => ListTile(
                leading: const Icon(Icons.circle, size: 10),
                title: Text(h.keterangan),
                subtitle: h.tanggal != null ? Text(formatTanggal(h.tanggal!)) : null,
              ),
            ),
            if (detail.berkas.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Lampiran', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              ...detail.berkas.map((b) => ListTile(
                    leading: const Icon(Icons.attach_file),
                    title: Text(b),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
