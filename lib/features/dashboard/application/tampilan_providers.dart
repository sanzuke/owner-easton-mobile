import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/theme/tampilan.dart';
import 'dashboard_providers.dart';

/// Pilihan tampilan tersimpan di perangkat (secure storage). Bawaan: otomatis (menurut usia).
class TampilanPilihanNotifier extends AsyncNotifier<TampilanPilihan> {
  @override
  Future<TampilanPilihan> build() async {
    final tersimpan = await ref.watch(secureTokenStorageProvider).readTampilan();
    return TampilanPilihan.dari(tersimpan);
  }

  Future<void> simpan(TampilanPilihan pilihan) async {
    await ref.read(secureTokenStorageProvider).saveTampilan(pilihan.name);
    state = AsyncData(pilihan);
  }
}

final tampilanPilihanProvider =
    AsyncNotifierProvider<TampilanPilihanNotifier, TampilanPilihan>(TampilanPilihanNotifier.new);

/// Tanggal sekarang — dipisah supaya bisa diganti di tes.
final sekarangProvider = Provider<DateTime>((ref) => DateTime.now());

/// Tampilan yang dipakai. Selama data belum dimuat -> Nyaman (aman untuk semua usia).
final tampilanModeProvider = Provider<TampilanMode>((ref) {
  final pilihan = ref.watch(tampilanPilihanProvider).valueOrNull ?? TampilanPilihan.otomatis;
  final lahir = ref.watch(dashboardSummaryProvider).valueOrNull?.tanggalLahir;
  return modeEfektif(pilihan, lahir, ref.watch(sekarangProvider));
});
