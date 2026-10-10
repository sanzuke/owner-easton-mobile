import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../data/utility_repository.dart';

final utilityRepositoryProvider = Provider<UtilityRepository>(
  (ref) => UtilityRepository(apiClient: ref.watch(apiClientProvider)),
);

/// Tahun yang dipilih di layar Utility; null = tahun terbaru dari server.
final utilityTahunProvider = StateProvider.autoDispose<int?>((ref) => null);

final utilityAirProvider = FutureProvider.autoDispose<UtilityAir>(
  (ref) => ref.watch(utilityRepositoryProvider).getAir(tahun: ref.watch(utilityTahunProvider)),
);
