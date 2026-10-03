import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/notifikasi/application/notifikasi_providers.dart';
import '../../features/notifikasi/presentation/notifikasi_screen.dart';

/// Tombol ikon lonceng notifikasi — muncul di app bar hampir semua layar
/// pada desain resmi, dengan badge jumlah belum dibaca.
class NotifikasiBellButton extends ConsumerWidget {
  const NotifikasiBellButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final belumDibaca = ref.watch(notifikasiBelumDibacaProvider).valueOrNull ?? 0;

    return IconButton(
      tooltip: 'Notifikasi',
      icon: Badge(
        isLabelVisible: belumDibaca > 0,
        label: Text(belumDibaca > 99 ? '99+' : '$belumDibaca'),
        child: const Icon(Icons.notifications_outlined),
      ),
      onPressed: () async {
        await Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const NotifikasiScreen()));
        ref.invalidate(notifikasiBelumDibacaProvider);
      },
    );
  }
}
