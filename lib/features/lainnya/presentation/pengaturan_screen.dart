import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_info_provider.dart';
import '../../auth/presentation/biometric_toggle_tile.dart';
import '../../auth/presentation/change_password_screen.dart';
import '../../dashboard/presentation/tampilan_screen.dart';

/// Pengaturan akun: tampilan aplikasi, biometrik (tersembunyi bila perangkat tak mendukung),
/// dan ubah password. Dibuka dari kartu Pengaturan di menu Lainnya.
class PengaturanScreen extends ConsumerWidget {
  const PengaturanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.tune_rounded),
              title: const Text('Tampilan aplikasi'),
              subtitle: const Text('Tema terang/gelap dan gaya tampilan'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TampilanScreen()),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const BiometricToggleTile(),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock_reset_rounded),
              title: const Text('Ubah password'),
              subtitle: const Text('Berlaku juga untuk portal web owner'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: const Text('Versi aplikasi'),
              subtitle: Text(ref.watch(appInfoProvider).maybeWhen(data: labelVersi, orElse: () => '-')),
            ),
          ),
        ],
      ),
    );
  }
}
