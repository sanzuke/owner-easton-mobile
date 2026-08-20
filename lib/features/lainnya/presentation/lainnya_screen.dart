import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/coming_soon_screen.dart';
import '../../../core/widgets/menu_icon_card.dart';
import '../../auth/application/auth_providers.dart';
import '../../profil/presentation/profil_screen.dart';
import '../../tiket/presentation/tiket_list_screen.dart';

/// Hub menu lainnya — Request(tiket), Utility, PBB, P3SRS, Pengaturan,
/// Keluar (mengikuti desain resmi grid 2 kolom).
class LainnyaScreen extends ConsumerWidget {
  const LainnyaScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Akhiri sesi dan keluar dari aplikasi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Keluar')),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(authRepositoryProvider).logout();
    ref.invalidate(authStateProvider);
    if (context.mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lainnya')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: const Text('Profil Saya'),
              subtitle: const Text('Lihat & edit data pribadi'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const ProfilScreen())),
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.1,
            children: [
              MenuIconCard(
                icon: Icons.build_outlined,
                iconColor: AppColors.pinkAccent,
                title: 'Request',
                subtitle: 'Perbaikan & bantuan',
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const TiketListScreen())),
              ),
              MenuIconCard(
                icon: Icons.water_drop_outlined,
                iconColor: AppColors.blueAccent,
                title: 'Utility',
                subtitle: 'Pemakaian air',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ComingSoonScreen(title: 'Utility'),
                  ),
                ),
              ),
              MenuIconCard(
                icon: Icons.description_outlined,
                iconColor: AppColors.primaryOlive,
                title: 'PBB',
                subtitle: 'Pajak bumi bangunan',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ComingSoonScreen(title: 'PBB')),
                ),
              ),
              MenuIconCard(
                icon: Icons.shield_outlined,
                iconColor: AppColors.destructive,
                title: 'P3SRS',
                subtitle: 'Dokumen perhimpunan',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ComingSoonScreen(title: 'P3SRS')),
                ),
              ),
              MenuIconCard(
                icon: Icons.settings_outlined,
                iconColor: Colors.grey.shade700,
                title: 'Pengaturan',
                subtitle: 'Tema & ukuran huruf',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ComingSoonScreen(title: 'Pengaturan')),
                ),
              ),
              MenuIconCard(
                icon: Icons.logout,
                iconColor: AppColors.destructive,
                title: 'Keluar',
                subtitle: 'Akhiri sesi',
                onTap: () => _logout(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
