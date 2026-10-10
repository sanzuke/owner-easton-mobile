import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/pagination/daftar_berhalaman.dart';
import '../../../core/providers/core_providers.dart';
import '../data/tagihan_repository.dart';

final tagihanRepositoryProvider = Provider<TagihanRepository>(
  (ref) => TagihanRepository(apiClient: ref.watch(apiClientProvider)),
);

/// Filter periode daftar tagihan (null = semua periode).
final periodeTagihanProvider = StateProvider.autoDispose<Periode?>(
  (ref) => null,
);

class TagihanListNotifier extends DaftarBerhalamanNotifier<Tagihan> {
  @override
  Periode? periodeAktif() => ref.watch(periodeTagihanProvider);

  @override
  Future<Halaman<Tagihan>> ambil(int halaman, Periode? periode) =>
      ref.read(tagihanRepositoryProvider).getHalaman(halaman, periode);
}

final tagihanListProvider =
    AsyncNotifierProvider.autoDispose<
      TagihanListNotifier,
      DaftarBerhalaman<Tagihan>
    >(TagihanListNotifier.new);

final tagihanDetailProvider = FutureProvider.autoDispose
    .family<TagihanDetail, String>(
      (ref, id) => ref.watch(tagihanRepositoryProvider).getDetail(id),
    );
