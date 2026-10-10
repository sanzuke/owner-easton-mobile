import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/menu_icon_card.dart';
import '../../../core/widgets/notifikasi_bell_button.dart';
import '../application/tiket_providers.dart';
import 'tiket_list_screen.dart';

/// Grid kategori tiket (Fit Out, Defect, Complain, Work Order, Access Card,
/// dst — dinamis dari `GET /tiket/tipe`) dengan jumlah permintaan per
/// kategori, persis layar "Request" di desain resmi. Tap kategori → daftar
/// tiket tipe itu (lihat TiketListScreen).
class RequestScreen extends ConsumerWidget {
  const RequestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tipeAsync = ref.watch(tiketTipeProvider);
    final listAsync = ref.watch(tiketListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Request'), actions: const [NotifikasiBellButton()]),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(tiketTipeProvider);
          ref.invalidate(tiketListProvider);
        },
        child: tipeAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => ListView(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 64),
                child: Center(child: Text('Gagal memuat tipe tiket: $err')),
              ),
            ],
          ),
          data: (tipeList) {
            final counts = <String, int>{};
            listAsync.whenData((tickets) {
              for (final t in tickets) {
                counts[t.tipe] = (counts[t.tipe] ?? 0) + 1;
              }
            });
            return GridView.count(
              padding: const EdgeInsets.all(16),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: tipeList.map((tipe) {
                final count = counts[tipe.nama] ?? 0;
                return MenuIconCard(
                  icon: Icons.build_outlined,
                  iconColor: AppColors.pinkAccent,
                  title: tipe.nama,
                  subtitle: count > 0 ? '$count permintaan' : 'Belum ada',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TiketListScreen(tipe: tipe),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}
