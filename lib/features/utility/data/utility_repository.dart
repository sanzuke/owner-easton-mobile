import '../../../core/network/api_client.dart';

/// Satu catatan meter air bulanan — `GET /utility/air` (docs/96b §9b).
class PemakaianAir {
  final String rekening;
  final int bulan;
  final int tahun;
  final num meterAwal;
  final num meterAkhir;
  final num pakai;

  /// Jumlah di invoice; null = bulan itu belum masuk invoice.
  final num? tagihan;

  const PemakaianAir({
    required this.rekening,
    required this.bulan,
    required this.tahun,
    required this.meterAwal,
    required this.meterAkhir,
    required this.pakai,
    this.tagihan,
  });

  factory PemakaianAir.fromJson(Map<String, dynamic> json) => PemakaianAir(
        rekening: json['rekening']?.toString() ?? '',
        bulan: int.tryParse(json['bulan']?.toString() ?? '') ?? 0,
        tahun: int.tryParse(json['tahun']?.toString() ?? '') ?? 0,
        meterAwal: num.tryParse(json['meter_awal']?.toString() ?? '') ?? 0,
        meterAkhir: num.tryParse(json['meter_akhir']?.toString() ?? '') ?? 0,
        pakai: num.tryParse(json['pakai']?.toString() ?? '') ?? 0,
        tagihan: num.tryParse(json['tagihan']?.toString() ?? ''),
      );
}

/// Riwayat air satu tahun + ringkasan unit.
class UtilityAir {
  /// Tahun yang ditampilkan; null bila unit belum punya rekening/catatan air.
  final int? tahun;
  final List<int> tahunTersedia;
  final num? meterTerakhir;
  final num tarifPerM3;
  final List<PemakaianAir> items;

  const UtilityAir({
    required this.tahun,
    required this.tahunTersedia,
    required this.meterTerakhir,
    required this.tarifPerM3,
    required this.items,
  });

  factory UtilityAir.fromJson(Map<String, dynamic> json) => UtilityAir(
        tahun: int.tryParse(json['tahun']?.toString() ?? ''),
        tahunTersedia: ((json['tahun_tersedia'] as List?) ?? const [])
            .map((e) => int.tryParse(e.toString()) ?? 0)
            .toList(growable: false),
        meterTerakhir: num.tryParse(json['meter_terakhir']?.toString() ?? ''),
        tarifPerM3: num.tryParse(json['tarif_per_m3']?.toString() ?? '') ?? 0,
        items: ((json['items'] as List?) ?? const [])
            .map((e) => PemakaianAir.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
      );
}

class UtilityRepository {
  UtilityRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  /// [tahun] null = tahun terbaru yang punya data (ditentukan server).
  Future<UtilityAir> getAir({int? tahun}) async {
    final res = await _api.get<UtilityAir>(
      '/utility/air',
      query: {'tahun': ?tahun},
      fromData: (json) => UtilityAir.fromJson(json as Map<String, dynamic>),
    );
    return res.data!;
  }
}
