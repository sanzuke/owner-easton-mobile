import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../data/tiket_repository.dart';

final tiketRepositoryProvider = Provider<TiketRepository>(
  (ref) => TiketRepository(apiClient: ref.watch(apiClientProvider)),
);

final tiketTipeProvider = FutureProvider.autoDispose<List<TiketTipe>>(
  (ref) => ref.watch(tiketRepositoryProvider).getTipe(),
);

final tiketListProvider = FutureProvider.autoDispose<List<Tiket>>(
  (ref) => ref.watch(tiketRepositoryProvider).getList(),
);

final tiketDetailProvider = FutureProvider.autoDispose.family<TiketDetail, String>(
  (ref, id) => ref.watch(tiketRepositoryProvider).getDetail(id),
);
