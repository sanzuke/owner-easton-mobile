import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/pagination/daftar_berhalaman.dart';
import '../../../core/providers/core_providers.dart';
import '../data/pembayaran_repository.dart';

final pembayaranRepositoryProvider = Provider<PembayaranRepository>(
  (ref) => PembayaranRepository(apiClient: ref.watch(apiClientProvider)),
);

/// Filter periode riwayat pembayaran (null = semua periode).
final periodePembayaranProvider = StateProvider.autoDispose<Periode?>(
  (ref) => null,
);

class RiwayatBayarNotifier extends DaftarBerhalamanNotifier<RiwayatBayar> {
  @override
  Periode? periodeAktif() => ref.watch(periodePembayaranProvider);

  @override
  Future<Halaman<RiwayatBayar>> ambil(int halaman, Periode? periode) =>
      ref.read(pembayaranRepositoryProvider).getHalaman(halaman, periode);
}

final riwayatBayarProvider =
    AsyncNotifierProvider.autoDispose<
      RiwayatBayarNotifier,
      DaftarBerhalaman<RiwayatBayar>
    >(RiwayatBayarNotifier.new);
