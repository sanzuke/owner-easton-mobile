import '../../../core/network/api_client.dart';

/// Unit BAST — `GET /api/v1/units` (publik, tanpa auth, dipakai dropdown
/// "Pilih Unit" di layar login). Query `?q=` filter kode unit, mengikuti
/// query yang sama dgn dropdown web (`db_unit.bast=1 AND bast.hapus=0`).
class Unit {
  final String idBast;
  final String kode;

  const Unit({required this.idBast, required this.kode});

  factory Unit.fromJson(Map<String, dynamic> json) => Unit(
        idBast: json['id_bast'].toString(),
        kode: json['kode']?.toString() ?? '-',
      );
}

class UnitRepository {
  UnitRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<List<Unit>> search(String query) async {
    final res = await _api.get<List<Unit>>(
      '/units',
      query: query.trim().isEmpty ? null : {'q': query.trim()},
      fromData: (json) =>
          (json as List).map((e) => Unit.fromJson(e as Map<String, dynamic>)).toList(growable: false),
    );
    return res.data ?? const [];
  }
}
