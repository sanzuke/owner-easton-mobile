import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_envelope.dart';
import '../../../core/theme/app_colors.dart';
import '../application/auth_providers.dart';
import '../data/unit_repository.dart';
import 'otp_verify_screen.dart';
import 'unit_picker_field.dart';

/// Layar login — No HP + ID BAST → kirim OTP WhatsApp (lihat docs/96 §2, §3).
/// Layout mengikuti desain resmi persis: badge ikon + judul brand di atas,
/// lalu kartu putih berisi form + footer bantuan.
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
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Badge ikon bulat-persegi olive + logo — sesuai desain resmi.
                  Container(
                    width: 72,
                    height: 72,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryOlive,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Image.asset(
                      'assets/app_icon_foreground.png',
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Easton Park Residence',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Building Management System',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // Kartu putih — form login + footer bantuan.
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Selamat Datang',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Masuk ke portal owner Anda',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey.shade600),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        _FieldLabel('Nomor WhatsApp'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _hpController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            hintText: 'Contoh: 08123456789',
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Nomor WhatsApp wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Masukkan nomor WhatsApp yang terdaftar',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey.shade500, fontSize: 11),
                        ),
                        const SizedBox(height: 16),
                        _FieldLabel('Pilih Unit'),
                        const SizedBox(height: 6),
                        UnitPickerField(
                          errorText: _unitErrorText,
                          onSelected: (unit) => setState(() {
                            _selectedUnit = unit;
                            _unitErrorText = null;
                          }),
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage!,
                            style: TextStyle(color: Theme.of(context).colorScheme.error),
                          ),
                        ],
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _submitting ? null : _submit,
                          icon: _submitting
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.login, size: 18),
                          label: Text(_submitting ? 'Memproses...' : 'Masuk'),
                        ),
                        const SizedBox(height: 20),
                        Divider(color: Colors.grey.shade200),
                        const SizedBox(height: 12),
                        Text(
                          'Butuh bantuan? Hubungi kami',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        const _HelpLine(icon: Icons.chat_bubble_outline, text: 'WhatsApp 082312122021'),
                        const SizedBox(height: 6),
                        const _HelpLine(icon: Icons.call_outlined, text: '0227780188'),
                        const SizedBox(height: 6),
                        const _HelpLine(icon: Icons.public, text: 'eprjatinangor.com'),
                      ],
                    ),
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

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

class _HelpLine extends StatelessWidget {
  const _HelpLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 15, color: AppColors.primaryOlive),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(color: AppColors.primaryOlive, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
