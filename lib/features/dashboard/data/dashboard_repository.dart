import '../../../core/network/api_client.dart';

/// Data ringkasan `GET /dashboard` — piutang, meter air terakhir, info unit
/// (lihat docs/96 update 19 Agustus).
class DashboardSummary {
  final num piutang;
  final num? meterAirTerakhir;
  final String? unitCode;
  final String? namaPemilik;

  const DashboardSummary({
    required this.piutang,
    this.meterAirTerakhir,
    this.unitCode,
    this.namaPemilik,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      piutang: (json['piutang'] ?? 0) as num,
      meterAirTerakhir: json['meter_air_terakhir'] as num?,
      unitCode: json['unit_code']?.toString() ?? json['id_bast']?.toString(),
      namaPemilik: json['nama_pemilik']?.toString(),
    );
  }
}

class DashboardRepository {
  DashboardRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<DashboardSummary> getSummary() async {
    final res = await _api.get<DashboardSummary>(
      '/dashboard',
      fromData: (json) => DashboardSummary.fromJson(json as Map<String, dynamic>),
    );
    return res.data!;
  }
}
