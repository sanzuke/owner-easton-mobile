import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/formatters.dart';
import '../application/tagihan_providers.dart';
import 'tagihan_detail_screen.dart';

/// Daftar tagihan/invoice — Tier 1 (lihat docs/96 §4).
class TagihanListScreen extends ConsumerWidget {
  const TagihanListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(tagihanListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tagihan')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(tagihanListProvider),
        child: listAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Gagal memuat tagihan: $err')),
          data: (list) {
            if (list.isEmpty) {
              return ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.only(top: 64),
                    child: Center(child: Text('Belum ada tagihan.')),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final tagihan = list[index];
                return Card(
                  child: ListTile(
                    title: Text(tagihan.nomorInvoice ?? tagihan.id),
                    subtitle: Text(tagihan.periode ?? '-'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(formatRupiah(tagihan.total)),
                        Text(
                          tagihan.status,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TagihanDetailScreen(id: tagihan.id),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
