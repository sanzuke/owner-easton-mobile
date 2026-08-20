import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/application/auth_providers.dart';

/// Cek status login (token tersimpan di secure storage) lalu arahkan ke
/// dashboard atau login.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<bool>>(authStateProvider, (previous, next) {
      next.whenData((isLoggedIn) {
        context.go(isLoggedIn ? '/dashboard' : '/login');
      });
    });

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
