import '../../../core/network/api_client.dart';

/// Riwayat pembayaran — `GET /pembayaran` (tabel `bayar` + join `db_via`,
/// lihat docs/96 update 19 Agustus).
class RiwayatBayar {
  final String id;
  final DateTime? tanggal;
  final num nominal;
  final String metode;
  final String status;

  const RiwayatBayar({
    required this.id,
    this.tanggal,
    required this.nominal,
    required this.metode,
    required this.status,
  });

  factory RiwayatBayar.fromJson(Map<String, dynamic> json) => RiwayatBayar(
        id: json['id']?.toString() ?? '',
        tanggal: DateTime.tryParse(json['tanggal']?.toString() ?? ''),
        nominal: (json['nominal'] ?? 0) as num,
        metode: json['metode']?.toString() ?? json['via']?.toString() ?? '-',
        status: json['status']?.toString() ?? '-',
      );
}

class PembayaranRepository {
  PembayaranRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<List<RiwayatBayar>> getRiwayat() async {
    final res = await _api.get<List<RiwayatBayar>>(
      '/pembayaran',
      fromData: (json) => (json as List)
          .map((e) => RiwayatBayar.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
    return res.data ?? const [];
  }
}
