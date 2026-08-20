import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../data/profil_repository.dart';

final profilRepositoryProvider = Provider<ProfilRepository>(
  (ref) => ProfilRepository(apiClient: ref.watch(apiClientProvider)),
);

final profilProvider = FutureProvider.autoDispose<Profil>(
  (ref) => ref.watch(profilRepositoryProvider).getProfil(),
);
