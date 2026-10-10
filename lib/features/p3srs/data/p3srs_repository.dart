import '../../../core/network/api_client.dart';

/// Kategori P3SRS — `GET /p3srs/kategori` (docs/96b §9d). `jenis` = laporan untuk kategori laporan
/// keuangan bulanan, selain itu artikel.
class KategoriP3srs {
  final int id;
  final String nama;
  final bool laporan;
  final int total;

  const KategoriP3srs({required this.id, required this.nama, required this.laporan, required this.total});

  factory KategoriP3srs.fromJson(Map<String, dynamic> json) => KategoriP3srs(
        id: int.tryParse(json['id_kategori']?.toString() ?? '') ?? 0,
        nama: json['nama']?.toString() ?? '-',
        laporan: json['jenis'] == 'laporan',
        total: int.tryParse(json['total']?.toString() ?? '') ?? 0,
      );
}

class ArtikelRingkas {
  final int id;
  final String judul;
  final String kategori;
  final DateTime? tanggal;
  final String? thumbUrl;

  const ArtikelRingkas({
    required this.id,
    required this.judul,
    required this.kategori,
    this.tanggal,
    this.thumbUrl,
  });

  factory ArtikelRingkas.fromJson(Map<String, dynamic> json) => ArtikelRingkas(
        id: int.tryParse(json['id_post']?.toString() ?? '') ?? 0,
        judul: json['judul']?.toString() ?? '-',
        kategori: json['kategori']?.toString() ?? '',
        tanggal: DateTime.tryParse(json['tanggal']?.toString() ?? ''),
        thumbUrl: json['thumb_url']?.toString(),
      );
}

class HalamanArtikel {
  final List<ArtikelRingkas> items;
  final int halaman;
  final int halamanTerakhir;

  const HalamanArtikel({required this.items, required this.halaman, required this.halamanTerakhir});

  bool get adaBerikutnya => halaman < halamanTerakhir;

  factory HalamanArtikel.fromJson(Map<String, dynamic> json) {
    final pg = json['pagination'];
    return HalamanArtikel(
      items: ((json['items'] as List?) ?? const [])
          .map((e) => ArtikelRingkas.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      halaman: pg is Map ? (int.tryParse(pg['current_page']?.toString() ?? '') ?? 1) : 1,
      halamanTerakhir: pg is Map ? (int.tryParse(pg['last_page']?.toString() ?? '') ?? 1) : 1,
    );
  }
}

class ArtikelDetail {
  final int id;
  final String judul;
  final String kategori;
  final DateTime? tanggal;
  final String? bannerUrl;

  /// HTML dari editor CMS.
  final String body;
  final int? pengunjung;

  const ArtikelDetail({
    required this.id,
    required this.judul,
    required this.kategori,
    this.tanggal,
    this.bannerUrl,
    required this.body,
    this.pengunjung,
  });

  factory ArtikelDetail.fromJson(Map<String, dynamic> json) => ArtikelDetail(
        id: int.tryParse(json['id_post']?.toString() ?? '') ?? 0,
        judul: json['judul']?.toString() ?? '-',
        kategori: json['kategori']?.toString() ?? '',
        tanggal: DateTime.tryParse(json['tanggal']?.toString() ?? ''),
        bannerUrl: json['banner_url']?.toString(),
        body: json['body']?.toString() ?? '',
        pengunjung: int.tryParse(json['pengunjung']?.toString() ?? ''),
      );
}

/// Laporan In/Out bulanan; [html] null saat [tersedia] false (belum disetujui bendahara & ketua).
class LaporanP3srs {
  final String bulan;
  final bool tersedia;
  final String? html;
  final int? pengunjung;

  const LaporanP3srs({required this.bulan, required this.tersedia, this.html, this.pengunjung});

  factory LaporanP3srs.fromJson(Map<String, dynamic> json) => LaporanP3srs(
        bulan: json['bulan']?.toString() ?? '',
        tersedia: json['tersedia'] == true,
        html: json['html']?.toString(),
        pengunjung: int.tryParse(json['pengunjung']?.toString() ?? ''),
      );
}

class P3srsRepository {
  P3srsRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<List<KategoriP3srs>> getKategori() async {
    final res = await _api.get<List<KategoriP3srs>>(
      '/p3srs/kategori',
      fromData: (json) => (json as List)
          .map((e) => KategoriP3srs.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
    return res.data ?? const [];
  }

  Future<HalamanArtikel> getArtikel({int? kategori, String? q, int halaman = 1}) async {
    final res = await _api.get<HalamanArtikel>(
      '/p3srs/artikel',
      query: {
        'kategori': ?kategori,
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
        'page': halaman,
        'per_page': 10,
      },
      fromData: (json) => HalamanArtikel.fromJson(json as Map<String, dynamic>),
    );
    return res.data!;
  }

  Future<ArtikelDetail> getDetail(int id) async {
    final res = await _api.get<ArtikelDetail>(
      '/p3srs/artikel/$id',
      fromData: (json) => ArtikelDetail.fromJson(json as Map<String, dynamic>),
    );
    return res.data!;
  }

  /// [bulan] format `YYYY-MM`.
  Future<LaporanP3srs> getLaporan(String bulan) async {
    final res = await _api.get<LaporanP3srs>(
      '/p3srs/laporan',
      query: {'bulan': bulan},
      fromData: (json) => LaporanP3srs.fromJson(json as Map<String, dynamic>),
    );
    return res.data!;
  }
}
