import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_envelope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/notifikasi_bell_button.dart';
import '../application/acara_providers.dart';
import '../data/acara_repository.dart';

/// Daftar acara/pengumuman + konfirmasi kehadiran — lihat catatan endpoint
/// di acara_repository.dart (backend belum tersedia).
class AcaraScreen extends ConsumerWidget {
  const AcaraScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(acaraListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Acara'), actions: const [NotifikasiBellButton()]),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(acaraListProvider),
        child: listAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => ListView(
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 64),
                child: Center(child: Text('Belum ada acara, atau layanan belum tersedia.')),
              ),
            ],
          ),
          data: (list) {
            if (list.isEmpty) {
              return ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.only(top: 64),
                    child: Center(child: Text('Belum ada acara.')),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) => _AcaraCard(acara: list[index]),
            );
          },
        ),
      ),
    );
  }
}

class _AcaraCard extends ConsumerStatefulWidget {
  const _AcaraCard({required this.acara});

  final Acara acara;

  @override
  ConsumerState<_AcaraCard> createState() => _AcaraCardState();
}

class _AcaraCardState extends ConsumerState<_AcaraCard> {
  bool _submitting = false;

  Future<void> _confirm() async {
    setState(() => _submitting = true);
    try {
      await ref.read(acaraRepositoryProvider).konfirmasiKehadiran(widget.acara.id);
      ref.invalidate(acaraListProvider);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final acara = widget.acara;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(acara.judul, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (acara.tanggal != null)
              Row(
                children: [
                  const Icon(Icons.schedule, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(formatTanggal(acara.tanggal!)),
                ],
              ),
            if (acara.lokasi != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(child: Text(acara.lokasi!)),
                ],
              ),
            ],
            if (acara.butuhKonfirmasi && acara.batasKonfirmasi != null) ...[
              const SizedBox(height: 4),
              Text(
                'Batas konfirmasi: ${formatTanggal(acara.batasKonfirmasi!)}',
                style: const TextStyle(color: AppColors.destructive, fontWeight: FontWeight.w600),
              ),
            ],
            if (acara.butuhKonfirmasi) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.navyAccent),
                  onPressed: acara.sudahKonfirmasi || _submitting ? null : _confirm,
                  icon: Icon(acara.sudahKonfirmasi ? Icons.check_circle : Icons.event_available),
                  label: Text(acara.sudahKonfirmasi ? 'Kehadiran Dikonfirmasi' : 'Konfirmasi Kehadiran'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
