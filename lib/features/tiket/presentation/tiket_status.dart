import 'package:flutter/material.dart';

import '../../../core/theme/tampilan.dart';
import '../../dashboard/presentation/dash_palette.dart';

/// Tiga kelompok status supaya mana yang belum selesai langsung terlihat:
/// baru (kuning), diproses (biru), selesai/ditutup (hijau). Ditolak merah.
/// Dipakai bersama oleh daftar dan detail tiket.
class GayaStatusTiket {
  const GayaStatusTiket({required this.kartu, required this.aksen});

  final Color kartu;
  final Color aksen;

  static GayaStatusTiket dari(String status, Brightness kecerahan) {
    final gelap = kecerahan == Brightness.dark;
    final p = DashPalette.untuk(TampilanMode.nyaman, kecerahan);
    switch (status) {
      case 'Ditutup':
      case 'Selesai':
        return GayaStatusTiket(kartu: p.okBg, aksen: p.okText);
      case 'Ditolak':
        return GayaStatusTiket(kartu: p.warnBg, aksen: p.warnText);
      case 'Diproses':
      case 'Menunggu Pembayaran':
        return gelap
            ? const GayaStatusTiket(kartu: Color(0xFF1B2A3D), aksen: Color(0xFF8DB6E8))
            : const GayaStatusTiket(kartu: Color(0xFFE3EEFB), aksen: Color(0xFF2F69A8));
      default: // Draft, Open = permintaan baru
        return gelap
            ? const GayaStatusTiket(kartu: Color(0xFF3A3316), aksen: Color(0xFFE8C75A))
            : const GayaStatusTiket(kartu: Color(0xFFFFF3D1), aksen: Color(0xFF8A6A0A));
    }
  }
}

/// Badge status tiket (pil kecil), warnanya mengikuti kelompok status.
class TiketStatusBadge extends StatelessWidget {
  const TiketStatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final gaya = GayaStatusTiket.dari(status, Theme.of(context).brightness);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: gaya.aksen.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        status,
        style: TextStyle(color: gaya.aksen, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
