import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/biometric_service.dart';
import '../../../core/providers/core_providers.dart';
import 'auth_providers.dart';

final biometricServiceProvider = Provider<BiometricService>((ref) => BiometricService());

/// Rute awal setelah splash:
/// - belum login                                   → `/login`
/// - login + buka cepat aktif + biometrik tersedia → `/unlock`
/// - login + buka cepat nonaktif                   → `/dashboard`
/// - login + buka cepat aktif tapi biometrik di perangkat sudah hilang
///   → fail-closed: sesi lokal dihapus, `/login`.
final startRouteProvider = FutureProvider<String>((ref) async {
  final loggedIn = await ref.watch(authRepositoryProvider).isLoggedIn();
  if (!loggedIn) return '/login';

  final storage = ref.watch(secureTokenStorageProvider);
  if (!await storage.isBiometricEnabled()) return '/dashboard';

  if (await ref.watch(biometricServiceProvider).isAvailable()) return '/unlock';

  await storage.clearToken();
  await storage.setBiometricEnabled(false);
  return '/login';
});
