import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../data/tagihan_repository.dart';

final tagihanRepositoryProvider = Provider<TagihanRepository>(
  (ref) => TagihanRepository(apiClient: ref.watch(apiClientProvider)),
);

final tagihanListProvider = FutureProvider.autoDispose<List<Tagihan>>(
  (ref) => ref.watch(tagihanRepositoryProvider).getList(),
);

final tagihanDetailProvider =
    FutureProvider.autoDispose.family<TagihanDetail, String>(
  (ref, id) => ref.watch(tagihanRepositoryProvider).getDetail(id),
);
