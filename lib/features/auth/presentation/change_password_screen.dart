import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_envelope.dart';
import '../application/auth_providers.dart';
import 'biometric_offer.dart';
import 'password_field.dart';

/// Ganti password.
/// - [force] = true: login pertama dengan password default (6 digit terakhir
///   NIK). Tanpa kolom password lama, tidak bisa kembali; sesudah sukses lanjut
///   ke dashboard. Pilihan lain hanya Keluar.
/// - [force] = false: menu "Ubah Password" dari tab Lainnya, password lama wajib.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key, this.force = false});

  final bool force;

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      await ref.read(authRepositoryProvider).changePassword(
            currentPassword: widget.force ? null : _currentController.text,
            newPassword: _newController.text,
            confirmPassword: _confirmController.text,
          );
      if (!mounted) return;
      if (widget.force) {
        await tawarkanBiometrik(context, ref);
        if (!mounted) return;
        context.go('/dashboard');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password berhasil diubah.')),
        );
        Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _keluar() async {
    await ref.read(authRepositoryProvider).logout().catchError((_) {});
    ref.invalidate(authStateProvider);
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return PopScope(
      canPop: !widget.force,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: !widget.force,
          title: Text(widget.force ? 'Buat Password Baru' : 'Ubah Password'),
          actions: [
            if (widget.force) TextButton(onPressed: _keluar, child: const Text('Keluar')),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.force
                        ? 'Demi keamanan, buat password baru sebelum memakai aplikasi. '
                            'Password ini juga berlaku untuk portal web owner.'
                        : 'Password baru juga berlaku untuk portal web owner.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),
                  if (!widget.force) ...[
                    const _Label('Password saat ini'),
                    const SizedBox(height: 8),
                    PasswordField(
                      controller: _currentController,
                      hintText: 'Password saat ini',
                      textInputAction: TextInputAction.next,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Password saat ini wajib diisi' : null,
                    ),
                    const SizedBox(height: 20),
                  ],
                  const _Label('Password baru'),
                  const SizedBox(height: 8),
                  PasswordField(
                    controller: _newController,
                    hintText: 'Minimal 8 karakter',
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      if (v == null || v.length < 8) return 'Password baru minimal 8 karakter';
                      if (!widget.force && v == _currentController.text) {
                        return 'Password baru tidak boleh sama dengan password lama';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  const _Label('Konfirmasi password baru'),
                  const SizedBox(height: 8),
                  PasswordField(
                    controller: _confirmController,
                    hintText: 'Ulangi password baru',
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submitting ? null : _submit(),
                    validator: (v) => v != _newController.text ? 'Konfirmasi password tidak sama' : null,
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline_rounded, size: 18, color: cs.error),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_errorMessage!, style: TextStyle(color: cs.error))),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary),
                          )
                        : const Text('Simpan password'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      );
}
