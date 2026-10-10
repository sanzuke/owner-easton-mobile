import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/formatters.dart';
import '../application/tagihan_providers.dart';
import '../data/tagihan_repository.dart';

/// Detail 1 tagihan + rincian item — PDF invoice masih Tier 2/blocker
/// dompdf, lihat docs/96 §5.
class TagihanDetailScreen extends ConsumerWidget {
  const TagihanDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(tagihanDetailProvider(id));

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Tagihan')),
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
                    Text(
                      detail.nomorInvoice ?? detail.id,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(detail.periode ?? '-'),
                    const SizedBox(height: 8),
                    Text('Status: ${detail.status}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Rincian', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            ...detail.items.map(
              (item) => ListTile(
                title: Text(item.nama),
                trailing: Text(formatRupiah(item.nominal)),
              ),
            ),
            const Divider(),
            ListTile(
              title: const Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: Text(
                formatRupiah(detail.total),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (detail.pembayaran.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Riwayat Pembayaran',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              ...detail.pembayaran.map((p) => _BarisPembayaran(p)),
            ],
          ],
        ),
      ),
    );
  }
}

class _BarisPembayaran extends StatelessWidget {
  const _BarisPembayaran(this.p);

  final TagihanPembayaran p;

  @override
  Widget build(BuildContext context) {
    final rincian = [
      if (p.tanggal != null) formatTanggal(p.tanggal!),
      if (p.creditNote) 'Credit Note' else if (p.metode != null) p.metode!,
    ].join(' • ');
    final url = p.cetakUrl;
    return Card(
      child: ListTile(
        title: Text(p.nomor, style: const TextStyle(fontSize: 13)),
        subtitle: Text('$rincian\n${formatRupiah(p.jumlah)}'),
        isThreeLine: true,
        trailing: url == null
            ? null
            : OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  textStyle: const TextStyle(fontSize: 13),
                ),
                onPressed: () async {
                  final uri = Uri.tryParse(url);
                  if (uri != null) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.print, size: 16),
                label: const Text('Print'),
              ),
      ),
    );
  }
}
