import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tab aktif di shell utama (0 Beranda, 1 Tagihan, 2 Acara, 3 Lainnya). Kartu fitur di
/// dashboard memakai ini untuk berpindah tab.
final shellTabProvider = StateProvider<int>((ref) => 0);
