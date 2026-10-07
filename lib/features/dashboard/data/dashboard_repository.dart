import '../../../core/network/api_client.dart';

/// Invoice terbaru milik unit (kartu "Tagihan Bulan Ini").
class TagihanTerbaru {
  final int idBilling;
  final String? invoice;
  final DateTime? jatuhTempo;
  final num total;
  final bool lunas;

  const TagihanTerbaru({
    required this.idBilling,
    this.invoice,
    this.jatuhTempo,
    required this.total,
    required this.lunas,
  });

  factory TagihanTerbaru.fromJson(Map<String, dynamic> json) => TagihanTerbaru(
        idBilling: (json['id_billing'] as num).toInt(),
        invoice: json['invoice']?.toString(),
        jatuhTempo: DateTime.tryParse(json['jatuh_tempo']?.toString() ?? ''),
        total: (json['total'] ?? 0) as num,
        lunas: json['lunas'] == true,
      );
}

/// Data ringkasan `GET /dashboard` (docs/96b §5): unit, pemilik (+ tanggal lahir untuk tema),
/// piutang, meter air, tagihan terbaru.
class DashboardSummary {
  final num piutang;
  final num? meterAirTerakhir;
  final String? unitCode;
  final String? tower;
  final String? namaPemilik;
  final String? jenisKelamin;
  final DateTime? tanggalLahir;
  final TagihanTerbaru? tagihanTerbaru;

  const DashboardSummary({
    required this.piutang,
    this.meterAirTerakhir,
    this.unitCode,
    this.tower,
    this.namaPemilik,
    this.jenisKelamin,
    this.tanggalLahir,
    this.tagihanTerbaru,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final unit = json['unit'] as Map<String, dynamic>?;
    final pemilik = json['pemilik'] as Map<String, dynamic>?;
    final tagihan = json['tagihan_terbaru'] as Map<String, dynamic>?;
    return DashboardSummary(
      piutang: (json['piutang'] ?? 0) as num,
      meterAirTerakhir: json['meter_air_terakhir'] as num?,
      unitCode: unit?['kode']?.toString(),
      tower: unit?['tower']?.toString(),
      namaPemilik: pemilik?['nama']?.toString(),
      jenisKelamin: pemilik?['jenis_kelamin']?.toString(),
      tanggalLahir: DateTime.tryParse(pemilik?['tanggal_lahir']?.toString() ?? ''),
      tagihanTerbaru: tagihan == null ? null : TagihanTerbaru.fromJson(tagihan),
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
