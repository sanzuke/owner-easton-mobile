import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../application/biometric_providers.dart';

/// Tawarkan buka cepat biometrik sekali, sesudah login (dan sesudah ganti
/// password wajib) — hanya bila perangkat punya biometrik terdaftar dan fitur
/// belum aktif.
Future<void> tawarkanBiometrik(BuildContext context, WidgetRef ref) async {
  final service = ref.read(biometricServiceProvider);
  final storage = ref.read(secureTokenStorageProvider);
  if (!await service.isAvailable() || await storage.isBiometricEnabled()) return;
  if (!context.mounted) return;

  final mau = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Aktifkan buka cepat?'),
      content: const Text(
        'Buka aplikasi berikutnya cukup dengan sidik jari atau wajah, tanpa mengetik password. '
        'Data biometrik tidak dikirim ke server.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Nanti')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Aktifkan')),
      ],
    ),
  );
  if (mau != true) return;
  if (await service.authenticate(reason: 'Verifikasi untuk mengaktifkan buka cepat')) {
    await storage.setBiometricEnabled(true);
  }
}
