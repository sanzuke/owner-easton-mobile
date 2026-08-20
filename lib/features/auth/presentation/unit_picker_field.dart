import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/auth_providers.dart';
import '../data/unit_repository.dart';

/// Dropdown "Pilih Unit" pada layar login — searchable, backed oleh
/// `GET /api/v1/units?q=` (publik, lihat docs/96 update terbaru). Ketik
/// minimal 1 karakter → debounce 350ms → tampilkan daftar hasil sebagai
/// panel di bawah field (bukan overlay, supaya sederhana & tidak butuh
/// package tambahan).
class UnitPickerField extends ConsumerStatefulWidget {
  const UnitPickerField({super.key, required this.onSelected, this.errorText});

  final ValueChanged<Unit> onSelected;
  final String? errorText;

  @override
  ConsumerState<UnitPickerField> createState() => _UnitPickerFieldState();
}

class _UnitPickerFieldState extends ConsumerState<UnitPickerField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  String _query = '';
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _showResults = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  void _select(Unit unit) {
    _controller.text = unit.kode;
    setState(() {
      _query = '';
      _showResults = false;
    });
    _focusNode.unfocus();
    widget.onSelected(unit);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: _onChanged,
          decoration: InputDecoration(
            hintText: 'Cari atau pilih unit...',
            suffixIcon: const Icon(Icons.expand_more),
            errorText: widget.errorText,
          ),
        ),
        if (_showResults) _UnitResultsPanel(query: _query, onSelected: _select),
      ],
    );
  }
}

class _UnitResultsPanel extends ConsumerWidget {
  const _UnitResultsPanel({required this.query, required this.onSelected});

  final String query;
  final ValueChanged<Unit> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitsAsync = ref.watch(unitSearchProvider(query));

    return Container(
      margin: const EdgeInsets.only(top: 4),
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: unitsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        ),
        error: (err, _) => Padding(
          padding: const EdgeInsets.all(12),
          child: Text('Gagal memuat unit: $err', style: const TextStyle(fontSize: 12)),
        ),
        data: (units) {
          if (units.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Unit tidak ditemukan.', style: TextStyle(fontSize: 12)),
            );
          }
          return ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: units.length,
            separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade200),
            itemBuilder: (context, index) {
              final unit = units[index];
              return ListTile(
                dense: true,
                title: Text(unit.kode),
                onTap: () => onSelected(unit),
              );
            },
          );
        },
      ),
    );
  }
}
