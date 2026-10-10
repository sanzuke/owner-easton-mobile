import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/filter_periode.dart';
import '../../../core/widgets/notifikasi_bell_button.dart';
import '../../../core/widgets/status_badge.dart';
import '../../pembayaran/presentation/pembayaran_screen.dart';
import '../application/tagihan_providers.dart';
import 'tagihan_detail_screen.dart';

/// Daftar tagihan/invoice — Tier 1 (lihat docs/96 §4). Tab Invoice/
/// Electricity berbentuk kartu ikon (persis desain resmi), bukan segmented
/// button; "Electricity" placeholder karena backend belum expose data
/// listrik terpisah (lihat docs/96 §5).
class TagihanListScreen extends ConsumerStatefulWidget {
  const TagihanListScreen({super.key});

  @override
  ConsumerState<TagihanListScreen> createState() => _TagihanListScreenState();
}

class _TagihanListScreenState extends ConsumerState<TagihanListScreen> {
  int _segment = 0;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_segment == 0 &&
          _scroll.hasClients &&
          _scroll.position.extentAfter < 300) {
        ref.read(tagihanListProvider.notifier).muatLagi();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(tagihanListProvider);
    final periode = ref.watch(periodeTagihanProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tagihan'),
        actions: [
          IconButton(
            tooltip: 'Riwayat Pembayaran',
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const PembayaranScreen())),
          ),
          const NotifikasiBellButton(),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(tagihanListProvider),
        child: ListView(
          controller: _scroll,
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: _TabTile(
                    icon: Icons.credit_card,
                    iconBg: AppColors.invoiceBadgeFg,
                    label: 'INVOICE',
                    selected: _segment == 0,
                    onTap: () => setState(() => _segment = 0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TabTile(
                    icon: Icons.bolt,
                    iconBg: AppColors.goldAccent,
                    label: 'ELECTRICITY',
                    selected: _segment == 1,
                    onTap: () => setState(() => _segment = 1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_segment == 0) ...[
              FilterPeriode(
                periode: periode,
                onChanged: (p) =>
                    ref.read(periodeTagihanProvider.notifier).state = p,
              ),
              const SizedBox(height: 12),
            ],
            if (_segment == 1)
              const Padding(
                padding: EdgeInsets.only(top: 48),
                child: Center(child: Text('Data listrik segera hadir.')),
              )
            else
              listAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, _) => Padding(
                  padding: const EdgeInsets.only(top: 48),
                  child: Center(child: Text('Gagal memuat tagihan: $err')),
                ),
                data: (daftar) {
                  final list = daftar.items;
                  if (list.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 48),
                      child: Center(
                        child: Text(
                          periode == null
                              ? 'Belum ada tagihan.'
                              : 'Tidak ada tagihan pada periode ini.',
                        ),
                      ),
                    );
                  }
                  final terakhir = list.first;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (periode == null)
                        Card(
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => TagihanDetailScreen(id: terakhir.id),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Tagihan Terakhir',
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          formatRupiah(terakhir.total),
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineSmall
                                              ?.copyWith(fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${terakhir.nomorInvoice ?? terakhir.id} · ${terakhir.periode ?? '-'}',
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right),
                                ],
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      ...list.map(
                        (tagihan) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          tagihan.nomorInvoice ?? tagihan.id,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleSmall,
                                        ),
                                      ),
                                      StatusBadge(status: tagihan.status),
                                    ],
                                  ),
                                  Text(
                                    tagihan.periode ?? '-',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        formatRupiah(tagihan.total),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      FilledButton.icon(
                                        style: FilledButton.styleFrom(
                                          backgroundColor: AppColors.brandGold,
                                          // Tema memberi minimumSize lebar tak hingga; di dalam Row itu merusak layout.
                                          minimumSize: const Size(0, 40),
                                        ),
                                        onPressed: () =>
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    TagihanDetailScreen(
                                                      id: tagihan.id,
                                                    ),
                                              ),
                                            ),
                                        icon: const Icon(
                                          Icons.print_outlined,
                                          size: 18,
                                        ),
                                        label: const Text('Print'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      PenutupDaftar(
                        state: daftar,
                        onCobaLagi: () =>
                            ref.read(tagihanListProvider.notifier).muatLagi(),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// Tab berbentuk kartu ikon (Invoice/Electricity) — persis desain resmi:
/// terpilih = border olive + ikon bg penuh; tidak terpilih = kartu polos.
class _TabTile extends StatelessWidget {
  const _TabTile({
    required this.icon,
    required this.iconBg,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppColors.brandGold
                : Theme.of(context).colorScheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: iconBg,
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
