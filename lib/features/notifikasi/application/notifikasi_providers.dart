import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../data/notifikasi_repository.dart';

final notifikasiRepositoryProvider = Provider<NotifikasiRepository>(
  (ref) => NotifikasiRepository(apiClient: ref.watch(apiClientProvider)),
);

final notifikasiListProvider = FutureProvider.autoDispose<List<Notifikasi>>(
  (ref) => ref.watch(notifikasiRepositoryProvider).getList(),
);
