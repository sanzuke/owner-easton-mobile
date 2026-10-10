import 'package:flutter/material.dart';

import '../pagination/daftar_berhalaman.dart';
import '../utils/formatters.dart';

/// Chip filter periode: "Semua periode" → pilih rentang tanggal (date range picker); chip berisi rentang + tombol hapus.
class FilterPeriode extends StatelessWidget {
  const FilterPeriode({
    super.key,
    required this.periode,
    required this.onChanged,
  });

  final Periode? periode;
  final ValueChanged<Periode?> onChanged;

  Future<void> _pilih(BuildContext context) async {
    final sekarang = DateTime.now();
    final hasil = await showDateRangePicker(
      context: context,
      locale: const Locale('id'),
      firstDate: DateTime(2015),
      lastDate: DateTime(sekarang.year + 1, 12, 31),
      initialDateRange: periode == null
          ? null
          : DateTimeRange(start: periode!.dari, end: periode!.sampai),
      helpText: 'Pilih periode',
      saveText: 'Terapkan',
    );
    if (hasil != null) onChanged(Periode(hasil.start, hasil.end));
  }

  @override
  Widget build(BuildContext context) {
    final p = periode;
    return Align(
      alignment: Alignment.centerLeft,
      child: InputChip(
        avatar: const Icon(Icons.date_range, size: 18),
        label: Text(
          p == null
              ? 'Semua periode'
              : '${formatTanggal(p.dari)} – ${formatTanggal(p.sampai)}',
        ),
        onPressed: () => _pilih(context),
        onDeleted: p == null ? null : () => onChanged(null),
        deleteButtonTooltipMessage: 'Hapus filter periode',
      ),
    );
  }
}

/// Baris bawah daftar infinite scroll: spinner saat memuat halaman berikut, atau tombol coba lagi bila gagal.
class PenutupDaftar extends StatelessWidget {
  const PenutupDaftar({
    super.key,
    required this.state,
    required this.onCobaLagi,
  });

  final DaftarBerhalaman<Object?> state;
  final VoidCallback onCobaLagi;

  @override
  Widget build(BuildContext context) {
    if (state.memuatLagi) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (state.gagalMuatLagi) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: TextButton.icon(
            onPressed: onCobaLagi,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Gagal memuat lagi. Coba lagi'),
          ),
        ),
      );
    }
    return const SizedBox(height: 8);
  }
}
