import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../data/va_repository.dart';

final vaRepositoryProvider = Provider<VaRepository>(
  (ref) => VaRepository(apiClient: ref.watch(apiClientProvider)),
);

/// Info VA satu invoice (key = id_billing). Di-invalidate saat tarik-untuk-segarkan.
final vaTagihanProvider = FutureProvider.autoDispose.family<VaTagihan, String>(
  (ref, idBilling) => ref.watch(vaRepositoryProvider).getVaTagihan(idBilling),
);
