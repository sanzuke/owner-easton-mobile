import 'package:intl/intl.dart';

/// Format angka jadi Rupiah, mis. 2143200 -> "Rp2.143.200".
String formatRupiah(num value) {
  final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
  return formatter.format(value);
}

/// Format tanggal ISO/backend jadi "21 Agu 2026".
String formatTanggal(DateTime date) {
  return DateFormat('d MMM y', 'id_ID').format(date);
}
