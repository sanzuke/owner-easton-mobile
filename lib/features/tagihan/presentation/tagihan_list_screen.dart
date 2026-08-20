import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/status_badge.dart';
import '../../pembayaran/presentation/pembayaran_screen.dart';
import '../application/tagihan_providers.dart';
import 'tagihan_detail_screen.dart';

/// Daftar tagihan/invoice — Tier 1 (lihat docs/96 §4). Segmented
/// Invoice/Electricity mengikuti desain resmi; "Electricity" placeholder
/// karena backend belum expose data listrik terpisah (lihat docs/96 §5).
class TagihanListScreen extends ConsumerStatefulWidget {
  const TagihanListScreen({super.key});

  @override
  ConsumerState<TagihanListScreen> createState() => _TagihanListScreenState();
}

class _TagihanListScreenState extends ConsumerState<TagihanListScreen> {
  int _segment = 0;

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(tagihanListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tagihan'),
        actions: [
          IconButton(
            tooltip: 'Riwayat Pembayaran',
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const PembayaranScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, icon: Icon(Icons.receipt_long), label: Text('INVOICE')),
                ButtonSegment(value: 1, icon: Icon(Icons.bolt), label: Text('ELECTRICITY')),
              ],
              selected: {_segment},
              onSelectionChanged: (s) => setState(() => _segment = s.first),
            ),
          ),
          Expanded(
            child: _segment == 1
                ? const Center(child: Text('Data listrik segera hadir.'))
                : RefreshIndicator(
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
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: list.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final tagihan = list[index];
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            tagihan.nomorInvoice ?? tagihan.id,
                                            style: Theme.of(context).textTheme.titleSmall,
                                          ),
                                        ),
                                        StatusBadge(status: tagihan.status),
                                      ],
                                    ),
                                    Text(
                                      tagihan.periode ?? '-',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          formatRupiah(tagihan.total),
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(fontWeight: FontWeight.bold),
                                        ),
                                        FilledButton.icon(
                                          style: FilledButton.styleFrom(
                                            backgroundColor: AppColors.primaryOlive,
                                          ),
                                          onPressed: () => Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) => TagihanDetailScreen(id: tagihan.id),
                                            ),
                                          ),
                                          icon: const Icon(Icons.print_outlined, size: 18),
                                          label: const Text('Print'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
