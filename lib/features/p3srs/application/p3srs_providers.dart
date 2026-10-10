import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../data/p3srs_repository.dart';

final p3srsRepositoryProvider = Provider<P3srsRepository>(
  (ref) => P3srsRepository(apiClient: ref.watch(apiClientProvider)),
);

final p3srsKategoriProvider = FutureProvider.autoDispose<List<KategoriP3srs>>(
  (ref) => ref.watch(p3srsRepositoryProvider).getKategori(),
);

final p3srsDetailProvider = FutureProvider.autoDispose.family<ArtikelDetail, int>(
  (ref, id) => ref.watch(p3srsRepositoryProvider).getDetail(id),
);

/// Laporan per bulan (`YYYY-MM`).
final p3srsLaporanProvider = FutureProvider.autoDispose.family<LaporanP3srs, String>(
  (ref, bulan) => ref.watch(p3srsRepositoryProvider).getLaporan(bulan),
);
