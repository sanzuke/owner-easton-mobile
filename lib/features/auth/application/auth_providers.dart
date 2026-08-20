import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../data/auth_repository.dart';
import '../data/unit_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    apiClient: ref.watch(apiClientProvider),
    tokenStorage: ref.watch(secureTokenStorageProvider),
  ),
);

final unitRepositoryProvider = Provider<UnitRepository>(
  (ref) => UnitRepository(apiClient: ref.watch(apiClientProvider)),
);

/// Hasil pencarian unit — di-family per query supaya Riverpod cache per
/// kata kunci ketikan (dipakai dropdown "Pilih Unit" di login).
final unitSearchProvider = FutureProvider.autoDispose.family<List<Unit>, String>(
  (ref, query) => ref.watch(unitRepositoryProvider).search(query),
);

/// Status login saat ini — dicek sekali di awal (splash) lalu diperbarui
/// setiap kali login/logout terjadi.
final authStateProvider = FutureProvider<bool>((ref) {
  return ref.watch(authRepositoryProvider).isLoggedIn();
});
