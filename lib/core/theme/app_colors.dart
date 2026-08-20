import 'package:flutter/material.dart';

/// Palet warna diambil dari desain resmi (Claude Artifact — Easton Park
/// Residence portal owner, dicek 21 Agustus 2026 setelah akses diberikan).
/// Nilai hex hasil estimasi visual dari screenshot prototipe, BUKAN dari
/// design token file — sesuaikan lagi kalau tim desain merilis token resmi
/// (mis. Figma variables).
class AppColors {
  AppColors._();

  /// Warna brand utama — header bar, tombol utama, ikon brand.
  static const Color primaryOlive = Color(0xFF8A7A22);

  /// Background utama app (krem/off-white), bukan putih polos.
  static const Color background = Color(0xFFEDE9E0);

  /// Tombol CTA sekunder yang kontras (mis. "Konfirmasi Kehadiran").
  static const Color navyAccent = Color(0xFF2B3358);

  /// Ikon & badge kategori "Request"/tiket.
  static const Color pinkAccent = Color(0xFFE23A6E);

  /// Ikon kategori Utility/meter air.
  static const Color blueAccent = Color(0xFF4C8DF0);

  /// Badge status "INVOICE" (belum dibayar).
  static const Color invoiceBadgeBg = Color(0xFFFBDCE3);
  static const Color invoiceBadgeFg = Color(0xFFC22A4E);

  /// Badge status "PAYMENT" (sudah dibayar).
  static const Color paymentBadgeBg = Color(0xFFDCEFD9);
  static const Color paymentBadgeFg = Color(0xFF3F7A3A);

  /// Aksi destruktif (mis. Keluar/logout).
  static const Color destructive = Color(0xFFD1352B);
}
