import 'package:flutter/material.dart';

/// Navigator akar GoRouter — dipakai untuk membuka layar dari luar pohon widget
/// (mis. ketukan notifikasi push).
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Untuk menampilkan SnackBar dari luar pohon widget (push masuk saat app terbuka).
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
