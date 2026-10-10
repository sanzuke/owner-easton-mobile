import 'package:flutter/material.dart';

import '../../auth/presentation/biometric_toggle_tile.dart';
import '../../auth/presentation/change_password_screen.dart';
import '../../dashboard/presentation/tampilan_screen.dart';

/// Pengaturan akun: tampilan aplikasi, biometrik (tersembunyi bila perangkat tak mendukung),
/// dan ubah password. Dibuka dari kartu Pengaturan di menu Lainnya.
class PengaturanScreen extends StatelessWidget {
  const PengaturanScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
        ],
      ),
    );
  }
}
