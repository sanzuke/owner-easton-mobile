import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/auth_providers.dart';
import '../application/biometric_providers.dart';

/// Gerbang buka cepat: token Sanctum sudah ada di secure storage, tapi app
/// baru dibuka setelah biometrik lolos. Prompt muncul otomatis.
class UnlockScreen extends ConsumerStatefulWidget {
  const UnlockScreen({super.key});

  @override
  ConsumerState<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends ConsumerState<UnlockScreen> {
  bool _checking = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  Future<void> _unlock() async {
    if (_checking) return;
    setState(() {
      _checking = true;
      _failed = false;
    });
    final ok = await ref.read(biometricServiceProvider).authenticate();
    if (!mounted) return;
    if (ok) {
      context.go('/dashboard');
    } else {
      setState(() {
        _checking = false;
        _failed = true;
      });
    }
  }

  /// Keluar dari sesi tersimpan dan login ulang dengan password.
  Future<void> _pakaiPassword() async {
    await ref.read(authRepositoryProvider).logout().catchError((_) {});
    ref.invalidate(authStateProvider);
    ref.invalidate(startRouteProvider);
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.fingerprint, size: 72),
              const SizedBox(height: 16),
              Text(
                'Buka dengan biometrik',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _failed
                    ? 'Verifikasi gagal atau dibatalkan.'
                    : 'Verifikasi sidik jari atau wajah untuk melanjutkan.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (_checking)
                const Center(child: CircularProgressIndicator())
              else ...[
                ElevatedButton(onPressed: _unlock, child: const Text('Coba lagi')),
                const SizedBox(height: 8),
                TextButton(onPressed: _pakaiPassword, child: const Text('Masuk dengan password')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
