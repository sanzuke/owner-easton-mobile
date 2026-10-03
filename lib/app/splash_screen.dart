import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/application/biometric_providers.dart';

/// Tentukan rute awal (login / gerbang biometrik / dashboard) — lihat
/// [startRouteProvider].
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<String>>(startRouteProvider, (previous, next) {
      next.whenData((route) => context.go(route));
    });

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
