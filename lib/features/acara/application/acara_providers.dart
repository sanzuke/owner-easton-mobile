import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../data/acara_repository.dart';

final acaraRepositoryProvider = Provider<AcaraRepository>(
  (ref) => AcaraRepository(apiClient: ref.watch(apiClientProvider)),
);

final acaraListProvider = FutureProvider.autoDispose<List<Acara>>(
  (ref) => ref.watch(acaraRepositoryProvider).getList(),
);
