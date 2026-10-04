import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_envelope.dart';
import '../application/auth_providers.dart';
import '../data/unit_repository.dart';
import 'unit_picker_field.dart';

/// Lupa password — kirim link reset ke email terdaftar (docs/96b §4.2b).
/// Halaman reset-nya sendiri dibuka di browser (portal web owner).
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hpController = TextEditingController();
  Unit? _selectedUnit;
  bool _submitting = false;
  String? _unitErrorText;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _hpController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final formValid = _formKey.currentState?.validate() ?? false;
    setState(() => _unitErrorText = _selectedUnit == null ? 'Pilih unit terlebih dahulu' : null);
    if (!formValid || _selectedUnit == null) return;
    setState(() {
      _submitting = true;
      _errorMessage = null;
      _successMessage = null;
    });
    try {
      final message = await ref.read(authRepositoryProvider).forgotPassword(
            noHp: _hpController.text.trim(),
            idBast: _selectedUnit!.idBast,
          );
      if (mounted) setState(() => _successMessage = message);
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Lupa Password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Masukkan nomor WhatsApp dan unit Anda. Kami akan mengirim link reset password '
                  'ke email yang terdaftar.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                Text('Nomor WhatsApp',
                    style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _hpController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: 'Contoh: 08123456789',
                    prefixIcon: Icon(Icons.chat_outlined, size: 20),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Nomor WhatsApp wajib diisi' : null,
                ),
                const SizedBox(height: 20),
                Text('Pilih Unit',
                    style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                UnitPickerField(
                  errorText: _unitErrorText,
                  onSelected: (unit) => setState(() {
                    _selectedUnit = unit;
                    _unitErrorText = null;
                  }),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  _Banner(text: _errorMessage!, color: cs.error, icon: Icons.error_outline_rounded),
                ],
                if (_successMessage != null) ...[
                  const SizedBox(height: 16),
                  _Banner(text: _successMessage!, color: cs.primary, icon: Icons.mark_email_read_outlined),
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
                      : const Text('Kirim link reset'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text, required this.color, required this.icon});

  final String text;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: color))),
        ],
      ),
    );
  }
}
