import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../data/acara_repository.dart';

final acaraRepositoryProvider = Provider<AcaraRepository>(
  (ref) => AcaraRepository(apiClient: ref.watch(apiClientProvider)),
);

final acaraListProvider = FutureProvider.autoDispose<DaftarAcara>(
  (ref) => ref.watch(acaraRepositoryProvider).getList(),
);

final acaraDetailProvider = FutureProvider.autoDispose.family<DetailAcara, String>(
  (ref, kode) => ref.watch(acaraRepositoryProvider).getDetail(kode),
);

final acaraQrProvider = FutureProvider.autoDispose.family<QrKehadiran, String>(
  (ref, kode) => ref.watch(acaraRepositoryProvider).getQr(kode),
);

final acaraVotingProvider = FutureProvider.autoDispose.family<DaftarVoting, String>(
  (ref, kode) => ref.watch(acaraRepositoryProvider).getVoting(kode),
);
