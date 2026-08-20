import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../data/pembayaran_repository.dart';

final pembayaranRepositoryProvider = Provider<PembayaranRepository>(
  (ref) => PembayaranRepository(apiClient: ref.watch(apiClientProvider)),
);

final riwayatBayarProvider = FutureProvider.autoDispose<List<RiwayatBayar>>(
  (ref) => ref.watch(pembayaranRepositoryProvider).getRiwayat(),
);
