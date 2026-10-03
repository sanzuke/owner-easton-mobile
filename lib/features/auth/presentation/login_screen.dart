import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_envelope.dart';
import '../application/auth_providers.dart';
import '../data/unit_repository.dart';
import 'otp_verify_screen.dart';
import 'unit_picker_field.dart';

/// Layar login — No HP + ID BAST → kirim OTP WhatsApp (lihat docs/96 §2, §3).
/// Gaya: latar polos, logo dalam wadah lembut, judul rata kiri, tanpa kartu
/// berbayang; seluruh warna dari ColorScheme (aman di mode terang & gelap).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hpController = TextEditingController();
  Unit? _selectedUnit;
  bool _submitting = false;
  String? _errorMessage;
  String? _unitErrorText;

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
    });
    try {
      final repo = ref.read(authRepositoryProvider);
      final result = await repo.requestOtp(
        noHp: _hpController.text.trim(),
        idBast: _selectedUnit!.idBast,
      );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OtpVerifyScreen(uid: result.uid, noHp: _hpController.text.trim()),
        ),
      );
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Image.asset('assets/app_icon_foreground.png', color: cs.primary),
                    ),
                    const SizedBox(height: 28),
                    Text('Selamat datang', style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    )),
                    const SizedBox(height: 6),
                    Text(
                      'Masuk ke portal owner Easton Park Residence.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 32),
                    _FieldLabel('Nomor WhatsApp'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _hpController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: '08123456789',
                        prefixIcon: Icon(Icons.phone_iphone_rounded, size: 20),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Nomor WhatsApp wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Kode OTP dikirim ke nomor WhatsApp yang terdaftar.',
                      style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 20),
                    _FieldLabel('Unit'),
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
                            Expanded(
                              child: Text(_errorMessage!, style: TextStyle(color: cs.error)),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: cs.onPrimary),
                            )
                          : const Text('Kirim kode OTP'),
                    ),
                    const SizedBox(height: 36),
                    Center(
                      child: Text(
                        'Butuh bantuan?',
                        style: theme.textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _HelpChip(icon: Icons.chat_bubble_outline_rounded, text: '0823 1212 2021'),
                        _HelpChip(icon: Icons.call_outlined, text: '(022) 778 0188'),
                        _HelpChip(icon: Icons.language_rounded, text: 'eprjatinangor.com'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

class _HelpChip extends StatelessWidget {
  const _HelpChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: cs.primary),
          const SizedBox(width: 6),
          Text(text, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}
