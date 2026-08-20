import 'package:flutter/material.dart';

import '../../features/notifikasi/presentation/notifikasi_screen.dart';

/// Tombol ikon lonceng notifikasi — muncul di app bar hampir semua layar
/// pada desain resmi. Dipisah jadi widget kecil supaya konsisten di semua
/// tempat pemakaian.
class NotifikasiBellButton extends StatelessWidget {
  const NotifikasiBellButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Notifikasi',
      icon: const Icon(Icons.notifications_outlined),
      onPressed: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const NotifikasiScreen())),
    );
  }
}
