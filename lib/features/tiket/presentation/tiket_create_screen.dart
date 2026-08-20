import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_envelope.dart';
import '../application/tiket_providers.dart';

/// Ajukan tiket baru — form dinamis lintas tipe (Defect/FO/General/WO/
/// Access/Corrective), lihat docs/96 §4 & update 19 Agustus.
class TiketCreateScreen extends ConsumerStatefulWidget {
  const TiketCreateScreen({super.key});

  @override
  ConsumerState<TiketCreateScreen> createState() => _TiketCreateScreenState();
}

class _TiketCreateScreenState extends ConsumerState<TiketCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _judulController = TextEditingController();
  final _keteranganController = TextEditingController();
  String? _selectedTipe;
  bool _submitting = false;

  @override
  void dispose() {
    _judulController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedTipe == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Pilih tipe tiket terlebih dahulu')));
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(tiketRepositoryProvider).create(
            tipe: _selectedTipe!,
            judul: _judulController.text.trim(),
            keterangan: _keteranganController.text.trim(),
          );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tipeAsync = ref.watch(tiketTipeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ajukan Tiket')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              tipeAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (err, _) => Text('Gagal memuat tipe tiket: $err'),
                data: (tipeList) => DropdownButtonFormField<String>(
                  initialValue: _selectedTipe,
                  decoration: const InputDecoration(labelText: 'Tipe Tiket'),
                  items: tipeList
                      .map((t) => DropdownMenuItem(value: t.kode, child: Text(t.nama)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedTipe = v),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _judulController,
                decoration: const InputDecoration(labelText: 'Judul'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Judul wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _keteranganController,
                decoration: const InputDecoration(labelText: 'Keterangan'),
                maxLines: 4,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Keterangan wajib diisi' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Kirim Tiket'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
