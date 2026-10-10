import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../data/p3srs_repository.dart';

final p3srsRepositoryProvider = Provider<P3srsRepository>(
  (ref) => P3srsRepository(apiClient: ref.watch(apiClientProvider)),
);

final p3srsKategoriProvider = FutureProvider.autoDispose<List<KategoriP3srs>>(
  (ref) => ref.watch(p3srsRepositoryProvider).getKategori(),
);

/// Detail artikel/berita, kunci = (sumber, id).
final artikelDetailProvider = FutureProvider.autoDispose.family<ArtikelDetail, (SumberArtikel, int)>(
  (ref, kunci) => ref.watch(p3srsRepositoryProvider).getDetail(kunci.$2, sumber: kunci.$1),
);

/// Laporan per bulan (`YYYY-MM`).
final p3srsLaporanProvider = FutureProvider.autoDispose.family<LaporanP3srs, String>(
  (ref, bulan) => ref.watch(p3srsRepositoryProvider).getLaporan(bulan),
);

/// Berita terbaru situs publik untuk beranda (5 teratas).
final beritaTerbaruProvider = FutureProvider.autoDispose<List<ArtikelRingkas>>((ref) async {
  final h = await ref.watch(p3srsRepositoryProvider).getArtikel(sumber: SumberArtikel.berita, perHalaman: 5);
  return h.items;
});
