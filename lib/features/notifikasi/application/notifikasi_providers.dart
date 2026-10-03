import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../data/notifikasi_repository.dart';

final notifikasiRepositoryProvider = Provider<NotifikasiRepository>(
  (ref) => NotifikasiRepository(apiClient: ref.watch(apiClientProvider)),
);

final notifikasiPageProvider = FutureProvider.autoDispose<NotifikasiPage>(
  (ref) => ref.watch(notifikasiRepositoryProvider).getPage(),
);

/// Jumlah belum dibaca untuk badge lonceng. 0 bila gagal dimuat (badge tidak
/// boleh merusak layar lain).
final notifikasiBelumDibacaProvider = FutureProvider.autoDispose<int>((ref) async {
  try {
    return (await ref.watch(notifikasiRepositoryProvider).getPage()).belumDibaca;
  } catch (_) {
    return 0;
  }
});
