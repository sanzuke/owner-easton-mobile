import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/notifikasi_bell_button.dart';
import '../application/acara_providers.dart';
import '../data/acara_repository.dart';
import 'acara_detail_screen.dart';

/// Tab Acara: daftar acara aktif & riwayat (`GET /acara`, docs/96b §11c).
class AcaraScreen extends ConsumerWidget {
  const AcaraScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(acaraListProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Acara'),
          actions: const [NotifikasiBellButton()],
          bottom: const TabBar(tabs: [Tab(text: 'Aktif'), Tab(text: 'Riwayat')]),
        ),
        body: listAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => RefreshIndicator(
            onRefresh: () async => ref.invalidate(acaraListProvider),
            child: ListView(children: const [
              Padding(
                padding: EdgeInsets.only(top: 64, left: 24, right: 24),
                child: Center(child: Text('Acara tidak dapat dimuat. Tarik ke bawah untuk mencoba lagi.')),
              ),
            ]),
          ),
          data: (d) => TabBarView(children: [
            _Daftar(items: d.aktif, kosong: 'Belum ada acara aktif.'),
            _Daftar(items: d.riwayat, kosong: 'Belum ada riwayat acara.'),
          ]),
        ),
      ),
    );
  }
}

class _Daftar extends ConsumerWidget {
  const _Daftar({required this.items, required this.kosong});

  final List<Acara> items;
  final String kosong;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(acaraListProvider),
      child: items.isEmpty
          ? ListView(children: [Padding(padding: const EdgeInsets.only(top: 64), child: Center(child: Text(kosong)))])
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _AcaraCard(acara: items[i]),
            ),
    );
  }
}

class _AcaraCard extends StatelessWidget {
  const _AcaraCard({required this.acara});

  final Acara acara;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => AcaraDetailScreen(kode: acara.kode)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(acara.nama, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (acara.tglMulai != null)
                Row(children: [
                  const Icon(Icons.schedule, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(formatTanggal(acara.tglMulai!)),
                ]),
              if (acara.lokasi.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(child: Text(acara.lokasi)),
                ]),
              ],
              const SizedBox(height: 8),
              if (acara.sudahRsvp)
                Row(children: [
                  const Icon(Icons.check_circle, size: 16, color: AppColors.navyAccent),
                  const SizedBox(width: 6),
                  Text('Kehadiran: ${labelKehadiran(acara.kehadiran!)}'),
                ])
              else if (acara.status == 1 && acara.batasRsvp != null)
                Text(
                  'Batas konfirmasi: ${formatTanggal(acara.batasRsvp!)}',
                  style: const TextStyle(color: AppColors.destructive, fontWeight: FontWeight.w600),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

String labelKehadiran(String k) => switch (k) {
      'online' => 'Online',
      'pemilik' => 'Offline (pemilik)',
      'dikuasakan' => 'Offline (dikuasakan)',
      _ => k,
    };
