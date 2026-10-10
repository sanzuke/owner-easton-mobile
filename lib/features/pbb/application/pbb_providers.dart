import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../data/pbb_repository.dart';

final pbbRepositoryProvider = Provider<PbbRepository>(
  (ref) => PbbRepository(apiClient: ref.watch(apiClientProvider)),
);

final pbbProvider = FutureProvider.autoDispose<PbbData>(
  (ref) => ref.watch(pbbRepositoryProvider).getPbb(),
);
