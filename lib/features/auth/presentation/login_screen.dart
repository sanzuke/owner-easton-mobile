import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_envelope.dart';
import '../application/auth_providers.dart';
import '../data/unit_repository.dart';
import 'biometric_offer.dart';
import 'forgot_password_screen.dart';
import 'password_field.dart';
import 'unit_picker_field.dart';

/// Layar login — No WhatsApp terdaftar + unit + password (docs/96b §4).
/// Password awal = 6 digit terakhir NIK; wajib diganti saat login pertama.
/// Gaya mengikuti portal web owner; seluruh warna dari ColorScheme.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hpController = TextEditingController();
  final _passwordController = TextEditingController();
  Unit? _selectedUnit;
  bool _submitting = false;
  String? _errorMessage;
  String? _unitErrorText;

  @override
  void dispose() {
    _hpController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final formValid = _formKey.currentState?.validate() ?? false;
    setState(
      () => _unitErrorText = _selectedUnit == null
          ? 'Pilih unit terlebih dahulu'
          : null,
    );
    if (!formValid || _selectedUnit == null) return;
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      final result = await ref.read(authRepositoryProvider).login(
            noHp: _hpController.text.trim(),
            idBast: _selectedUnit!.idBast,
            password: _passwordController.text,
          );
      ref.invalidate(authStateProvider);
      if (!mounted) return;
      if (result.mustChangePassword) {
        context.go('/ganti-password');
        return;
      }
      await tawarkanBiometrik(context, ref);
      if (!mounted) return;
      context.go('/dashboard');
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Kepala: ubin logo emas + nama kompleks (mengikuti portal web).
                    Center(
                      child: Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: cs.primary,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: cs.primary.withValues(alpha: 0.25),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.apartment_rounded,
                          color: cs.onPrimary,
                          size: 34,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Easton Park Residence',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Building Management System',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Kartu form.
                    Container(
                      padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: cs.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.lock_rounded,
                                color: cs.primary,
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Selamat Datang',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Masuk ke portal owner Anda',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 26),
                          const _FieldLabel('Nomor WhatsApp'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _hpController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              hintText: 'Contoh: 08123456789',
                              prefixIcon: Icon(Icons.chat_outlined, size: 20),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Nomor WhatsApp wajib diisi'
                                : null,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Nomor WhatsApp yang terdaftar pada unit Anda.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const _FieldLabel('Pilih Unit'),
                          const SizedBox(height: 8),
                          UnitPickerField(
                            errorText: _unitErrorText,
                            onSelected: (unit) => setState(() {
                              _selectedUnit = unit;
                              _unitErrorText = null;
                            }),
                          ),
                          const SizedBox(height: 20),
                          const _FieldLabel('Password'),
                          const SizedBox(height: 8),
                          PasswordField(
                            controller: _passwordController,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submitting ? null : _submit(),
                            validator: (v) => (v == null || v.isEmpty) ? 'Password wajib diisi' : null,
                          ),
                          const SizedBox(height: 6),
                          Text.rich(
                            TextSpan(
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                              children: [
                                const TextSpan(
                                  text: 'Pertama kali login? Gunakan 6 digit terakhir NIK Anda. ',
                                ),
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.baseline,
                                  baseline: TextBaseline.alphabetic,
                                  child: GestureDetector(
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                                    ),
                                    child: Text(
                                      'Lupa password?',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: cs.primary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
                                  Icon(
                                    Icons.error_outline_rounded,
                                    size: 18,
                                    color: cs.error,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: TextStyle(color: cs.error),
                                    ),
                                  ),
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
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: cs.onPrimary,
                                    ),
                                  )
                                : const Text('Masuk'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Center(
                      child: Text(
                        'Butuh bantuan?',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _HelpChip(
                          icon: Icons.chat_bubble_outline_rounded,
                          text: '0823 1212 2021',
                        ),
                        _HelpChip(
                          icon: Icons.call_outlined,
                          text: '(022) 778 0188',
                        ),
                        _HelpChip(
                          icon: Icons.language_rounded,
                          text: 'eprjatinangor.com',
                        ),
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
      style: Theme.of(
        context,
      ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
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
