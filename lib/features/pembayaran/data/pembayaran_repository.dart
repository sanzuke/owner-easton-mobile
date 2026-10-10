import '../../../core/network/api_client.dart';
import '../../../core/pagination/daftar_berhalaman.dart';

/// Riwayat pembayaran — `GET /pembayaran` (tabel `bayar` + join `db_via`,
/// docs/96b §7). Respons: `data: {items: [...], pagination: {current_page, last_page, total}}`.
class RiwayatBayar {
  final String id;
  final String kwitansi;
  final DateTime? tanggal;
  final num jumlah;
  final String metode;
  final String keterangan;

  const RiwayatBayar({
    required this.id,
    this.kwitansi = '',
    this.tanggal,
    required this.jumlah,
    required this.metode,
    this.keterangan = '',
  });

  factory RiwayatBayar.fromJson(Map<String, dynamic> json) => RiwayatBayar(
    id: json['id_bayar']?.toString() ?? '',
    kwitansi: json['kwitansi']?.toString() ?? '',
    tanggal: DateTime.tryParse(json['tanggal']?.toString() ?? ''),
    jumlah: num.tryParse(json['jumlah']?.toString() ?? '') ?? 0,
    metode: (json['metode']?.toString().trim().isNotEmpty ?? false)
        ? json['metode'].toString().trim()
        : '-',
    keterangan: json['keterangan']?.toString().trim() ?? '',
  );
}

class PembayaranRepository {
  PembayaranRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  static const _perHalaman = 20;

  /// Satu halaman `GET /pembayaran` (terbaru dulu), opsional dibatasi [periode] (tanggal pembayaran, inklusif).
  Future<Halaman<RiwayatBayar>> getHalaman(
    int halaman,
    Periode? periode,
  ) async {
    final res = await _api.get<Halaman<RiwayatBayar>>(
      '/pembayaran',
      query: {'page': halaman, 'per_page': _perHalaman, ...?periode?.query},
      fromData: (json) => Halaman.dariJson(json, RiwayatBayar.fromJson),
    );
    return res.data ?? const Halaman([], 1);
  }
}
