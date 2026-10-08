import '../../../core/network/api_client.dart';

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

  static const _perHalaman = 50;

  /// Ambil seluruh riwayat (semua halaman; server membatasi 50 per halaman).
  Future<List<RiwayatBayar>> getRiwayat() async {
    final hasil = <RiwayatBayar>[];
    var halaman = 1;
    var terakhir = 1;
    do {
      final res = await _api.get<_Halaman>(
        '/pembayaran',
        query: {'page': halaman, 'per_page': _perHalaman},
        fromData: (json) => _Halaman.fromJson(json as Map<String, dynamic>),
      );
      final h = res.data;
      if (h == null) break;
      hasil.addAll(h.items);
      terakhir = h.lastPage;
      halaman++;
    } while (halaman <= terakhir);
    return List.unmodifiable(hasil);
  }
}

class _Halaman {
  const _Halaman(this.items, this.lastPage);

  final List<RiwayatBayar> items;
  final int lastPage;

  factory _Halaman.fromJson(Map<String, dynamic> json) {
    final pg = json['pagination'];
    return _Halaman(
      ((json['items'] as List?) ?? const [])
          .map((e) => RiwayatBayar.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      pg is Map ? (int.tryParse(pg['last_page']?.toString() ?? '') ?? 1) : 1,
    );
  }
}
