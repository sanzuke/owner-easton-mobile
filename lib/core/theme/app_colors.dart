import 'package:flutter/material.dart';

/// Palet warna. Revisi 4 Okt 2026: disamakan dengan portal web owner
/// (owner.eprjatinangor.com) — emas-mustard sebagai warna brand, latar
/// hampir putih, netral abu dingin. Skema light/dark lengkap ada di
/// `app_theme.dart`; konstanta di sini dipakai widget yang butuh warna brand
/// tetap (ikon, badge).
class AppColors {
  AppColors._();

  /// Warna brand utama (emas-mustard, sama dengan portal web).
  static const Color brandGold = Color(0xFFB3A22C);

  /// Latar utama mode terang (hampir putih, seperti portal web).
  static const Color background = Color(0xFFF8F9FA);

  /// Aksen sekunder (slate) untuk CTA kontras.
  static const Color navyAccent = Color(0xFF374151);

  /// Aksen hangat untuk ikon penekanan.
  static const Color goldAccent = Color(0xFFC9A93A);

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
