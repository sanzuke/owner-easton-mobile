import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../application/notifikasi_providers.dart';

/// Layar inbox notifikasi — dibuka dari ikon lonceng di app bar.
class NotifikasiScreen extends ConsumerWidget {
  const NotifikasiScreen({super.key});

  void _refresh(WidgetRef ref) {
    ref.invalidate(notifikasiPageProvider);
    ref.invalidate(notifikasiBelumDibacaProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageAsync = ref.watch(notifikasiPageProvider);
    final repo = ref.watch(notifikasiRepositoryProvider);
    final adaBelumDibaca = (pageAsync.valueOrNull?.belumDibaca ?? 0) > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          if (adaBelumDibaca)
            TextButton(
              onPressed: () async {
                await repo.tandaiSemuaDibaca();
                _refresh(ref);
              },
              child: const Text('Tandai semua dibaca'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(ref),
        child: pageAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => ListView(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 64),
                child: Center(
                  child: Column(
                    children: [
                      const Text('Gagal memuat notifikasi.'),
                      TextButton(onPressed: () => _refresh(ref), child: const Text('Coba lagi')),
                    ],
                  ),
                ),
              ),
            ],
          ),
          data: (page) {
            if (page.items.isEmpty) {
              return ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.only(top: 64),
                    child: Center(child: Text('Belum ada notifikasi.')),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: page.items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final n = page.items[index];
                return Card(
                  child: ListTile(
                    onTap: n.sudahDibaca
                        ? null
                        : () async {
                            await repo.tandaiDibaca(n.id);
                            _refresh(ref);
                          },
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.brandGold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.notifications_outlined, color: AppColors.brandGold),
                    ),
                    title: Text(
                      n.judul,
                      style: TextStyle(fontWeight: n.sudahDibaca ? FontWeight.normal : FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (n.pesan.isNotEmpty) Text(n.pesan),
                        if (n.waktu != null)
                          Text(
                            formatTanggal(n.waktu!),
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                      ],
                    ),
                    trailing: n.sudahDibaca
                        ? null
                        : const Icon(Icons.circle, size: 10, color: AppColors.brandGold),
                    isThreeLine: n.pesan.isNotEmpty,
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
