import 'package:flutter/material.dart';

/// Palet warna. Revisi 3 Okt 2026: nada dibuat lebih tenang (sage/olive
/// teredam + netral hangat) menggantikan olive-kuning yang terlalu mencolok
/// dari estimasi screenshot prototipe awal. Skema light/dark lengkap ada di
/// `app_theme.dart`; konstanta di sini dipakai widget yang butuh warna brand
/// tetap (ikon, badge).
class AppColors {
  AppColors._();

  /// Warna brand utama (sage-olive teredam) — aksen, ikon brand, tombol.
  static const Color primaryOlive = Color(0xFF5F7340);

  /// Latar utama mode terang (netral hangat, bukan krem pekat).
  static const Color background = Color(0xFFF7F6F2);

  /// Aksen sekunder (slate) untuk CTA kontras.
  static const Color navyAccent = Color(0xFF39455C);

  /// Aksen hangat untuk ikon penekanan (dulu kuning menyala 0xFFE0B400).
  static const Color goldAccent = Color(0xFFC49A3A);

  /// Ikon & badge kategori "Request"/tiket.
  static const Color pinkAccent = Color(0xFFD4587C);

  /// Ikon kategori Utility/meter air.
  static const Color blueAccent = Color(0xFF5C86D6);

  /// Badge status "INVOICE" (belum dibayar).
  static const Color invoiceBadgeBg = Color(0xFFFBE3E8);
  static const Color invoiceBadgeFg = Color(0xFFB8345A);

  /// Badge status "PAYMENT" (sudah dibayar).
  static const Color paymentBadgeBg = Color(0xFFE1EEDD);
  static const Color paymentBadgeFg = Color(0xFF3F7A3A);

  /// Aksi destruktif (mis. Keluar/logout).
  static const Color destructive = Color(0xFFC8423A);
}
