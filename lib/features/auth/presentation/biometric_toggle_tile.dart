import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../application/biometric_providers.dart';

/// Pengaktifan / penonaktifan buka cepat biometrik. Mengaktifkan WAJIB lolos
/// verifikasi biometrik dulu, supaya tidak bisa diaktifkan tanpa pemilik
/// perangkat. Tersembunyi bila perangkat tak punya biometrik terdaftar.
class BiometricToggleTile extends ConsumerStatefulWidget {
  const BiometricToggleTile({super.key});

  @override
  ConsumerState<BiometricToggleTile> createState() => _BiometricToggleTileState();
}

class _BiometricToggleTileState extends ConsumerState<BiometricToggleTile> {
  bool? _available;
  bool _enabled = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final available = await ref.read(biometricServiceProvider).isAvailable();
    final enabled = await ref.read(secureTokenStorageProvider).isBiometricEnabled();
    if (!mounted) return;
    setState(() {
      _available = available;
      _enabled = enabled;
    });
  }

  Future<void> _toggle(bool value) async {
    if (_busy) return;
    setState(() => _busy = true);
    final storage = ref.read(secureTokenStorageProvider);
    var ok = true;
    if (value) {
      ok = await ref
          .read(biometricServiceProvider)
          .authenticate(reason: 'Verifikasi untuk mengaktifkan buka cepat');
    }
    if (ok) await storage.setBiometricEnabled(value);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok) _enabled = value;
    });
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verifikasi gagal, buka cepat tidak diaktifkan.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_available != true) return const SizedBox.shrink();
    return Card(
      child: SwitchListTile(
        secondary: const Icon(Icons.fingerprint),
        title: const Text('Buka cepat biometrik'),
        subtitle: const Text('Sidik jari / wajah saat membuka aplikasi'),
        value: _enabled,
        onChanged: _busy ? null : _toggle,
      ),
    );
  }
}
