import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_envelope.dart';
import '../../auth/application/auth_providers.dart';
import '../application/profil_providers.dart';
import '../data/profil_repository.dart';

/// Lihat & edit profil pemilik — upload KTP/KK ada di Tier 2 (lihat docs/96 §4).
class ProfilScreen extends ConsumerStatefulWidget {
  const ProfilScreen({super.key});

  @override
  ConsumerState<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends ConsumerState<ProfilScreen> {
  bool _editing = false;
  bool _saving = false;
  final _namaController = TextEditingController();
  final _hpController = TextEditingController();
  final _emailController = TextEditingController();
  final _alamatController = TextEditingController();

  void _startEdit(Profil profil) {
    _namaController.text = profil.nama;
    _hpController.text = profil.hp;
    _emailController.text = profil.email ?? '';
    _alamatController.text = profil.alamat ?? '';
    setState(() => _editing = true);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(profilRepositoryProvider).updateProfil(
            nama: _namaController.text.trim(),
            hp: _hpController.text.trim(),
            email: _emailController.text.trim(),
            alamat: _alamatController.text.trim(),
          );
      ref.invalidate(profilProvider);
      if (mounted) setState(() => _editing = false);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    await ref.read(authRepositoryProvider).logout();
    ref.invalidate(authStateProvider);
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final profilAsync = ref.watch(profilProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: profilAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Gagal memuat profil: $err')),
        data: (profil) {
          if (!_editing) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage:
                      profil.fotoUrl != null ? NetworkImage(profil.fotoUrl!) : null,
                  child: profil.fotoUrl == null ? const Icon(Icons.person, size: 40) : null,
                ),
                const SizedBox(height: 16),
                _ProfilTile(label: 'Nama', value: profil.nama),
                _ProfilTile(label: 'No. HP', value: profil.hp),
                _ProfilTile(label: 'Email', value: profil.email ?? '-'),
                _ProfilTile(label: 'Alamat', value: profil.alamat ?? '-'),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => _startEdit(profil),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit Profil'),
                ),
              ],
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _namaController,
                decoration: const InputDecoration(labelText: 'Nama'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _hpController,
                decoration: const InputDecoration(labelText: 'No. HP'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _alamatController,
                decoration: const InputDecoration(labelText: 'Alamat'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => setState(() => _editing = false),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Simpan'),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfilTile extends StatelessWidget {
  const _ProfilTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: Theme.of(context).textTheme.bodySmall),
      subtitle: Text(value, style: Theme.of(context).textTheme.bodyLarge),
    );
  }
}
