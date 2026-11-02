import 'package:flutter/material.dart';

import '../network/api_envelope.dart';

/// Pesan galat ramah untuk pengguna dari exception apa pun.
/// 401 -> sesi berakhir (app belum punya interceptor logout otomatis, jadi layar hanya
/// menampilkan pesan, sama seperti layar lain); tanpa status -> masalah koneksi.
String pesanGalat(Object error, {String fallback = 'Data tidak dapat dimuat. Coba lagi.'}) {
  if (error is ApiException) {
    if (error.statusCode == 401) {
      return 'Sesi Anda berakhir. Keluar lalu masuk kembali dari menu Lainnya.';
    }
    if (error.statusCode == null) {
      return 'Tidak bisa terhubung ke server. Periksa koneksi lalu coba lagi.';
    }
    if (error.message.isNotEmpty) return error.message;
  }
  return fallback;
}

/// Keadaan galat satu layar: pesan + tombol "Coba lagi". Berupa [ListView] agar bisa dibungkus
/// [RefreshIndicator] (tarik untuk memuat ulang) tanpa overflow di layar pendek.
class GalatView extends StatelessWidget {
  const GalatView({
    super.key,
    required this.error,
    required this.onCoba,
    this.fallback = 'Data tidak dapat dimuat. Coba lagi.',
  });

  final Object error;
  final VoidCallback onCoba;
  final String fallback;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 24),
      children: [
        Icon(Icons.cloud_off_outlined, size: 40, color: cs.onSurfaceVariant),
        const SizedBox(height: 12),
        Text(pesanGalat(error, fallback: fallback), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Center(
          child: FilledButton(
            style: const ButtonStyle(minimumSize: WidgetStatePropertyAll(Size(160, 44))),
            onPressed: onCoba,
            child: const Text('Coba lagi'),
          ),
        ),
      ],
    );
  }
}

/// Keadaan kosong satu layar (juga [ListView] agar bisa ditarik-segarkan).
class KosongView extends StatelessWidget {
  const KosongView({super.key, required this.pesan, this.ikon = Icons.inbox_outlined});

  final String pesan;
  final IconData ikon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 24),
      children: [
        Icon(ikon, size: 40, color: cs.onSurfaceVariant),
        const SizedBox(height: 12),
        Text(pesan, textAlign: TextAlign.center),
      ],
    );
  }
}
