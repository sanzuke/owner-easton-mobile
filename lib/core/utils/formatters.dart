import 'package:intl/intl.dart';

/// Format angka jadi Rupiah, mis. 2143200 -> "Rp2.143.200".
String formatRupiah(num value) {
  final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
  return formatter.format(value);
}

/// Format tanggal ISO/backend jadi "DD MMM YYYY", mis. "05 Jul 2026".
String formatTanggal(DateTime date) {
  return DateFormat('dd MMM yyyy', 'id_ID').format(date);
}

/// Seperti [formatTanggal] untuk tanggal teks dari API ("2026-07-05" / "2026-07-05 09:00:00");
/// kosong → "-", teks yang bukan tanggal ditampilkan apa adanya.
String formatTanggalIso(String? iso) {
  if (iso == null || iso.trim().isEmpty) return '-';
  final d = DateTime.tryParse(iso);
  return d == null ? iso : formatTanggal(d);
}

/// Tanggal + jam "21 Agu 2026, 09:00".
String formatTanggalWaktu(DateTime date) {
  return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(date);
}

/// Format tanggal panjang "10 Agustus 2026".
String formatTanggalPanjang(DateTime date) {
  return DateFormat('d MMMM y', 'id_ID').format(date);
}
