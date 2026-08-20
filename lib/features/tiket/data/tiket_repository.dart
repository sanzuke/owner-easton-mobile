import '../../../core/network/api_client.dart';

/// Tipe tiket — `GET /tiket/tipe` (6 tipe: Defect, FO, General/RC, WO,
/// Access, Corrective — lihat docs/96 §2).
class TiketTipe {
  final String kode;
  final String nama;

  const TiketTipe({required this.kode, required this.nama});

  factory TiketTipe.fromJson(Map<String, dynamic> json) => TiketTipe(
        kode: json['kode']?.toString() ?? json['id']?.toString() ?? '',
        nama: json['nama']?.toString() ?? '-',
      );
}

class Tiket {
  final String id;
  final String judul;
  final String tipe;
  final String status;
  final DateTime? tanggal;

  const Tiket({
    required this.id,
    required this.judul,
    required this.tipe,
    required this.status,
    this.tanggal,
  });

  factory Tiket.fromJson(Map<String, dynamic> json) => Tiket(
        id: json['id']?.toString() ?? json['id_tiket']?.toString() ?? '',
        judul: json['judul']?.toString() ?? json['keterangan']?.toString() ?? '-',
        tipe: json['tipe']?.toString() ?? '-',
        status: json['status']?.toString() ?? '-',
        tanggal: DateTime.tryParse(json['tanggal']?.toString() ?? ''),
      );
}

class TiketDetail extends Tiket {
  final List<TiketHistori> histori;
  final List<String> berkas;

  const TiketDetail({
    required super.id,
    required super.judul,
    required super.tipe,
    required super.status,
    super.tanggal,
    required this.histori,
    required this.berkas,
  });

  factory TiketDetail.fromJson(Map<String, dynamic> json) {
    final base = Tiket.fromJson(json);
    final rawHistori = (json['histori'] as List?) ?? const [];
    final rawBerkas = (json['berkas'] as List?) ?? const [];
    return TiketDetail(
      id: base.id,
      judul: base.judul,
      tipe: base.tipe,
      status: base.status,
      tanggal: base.tanggal,
      histori: rawHistori
          .map((e) => TiketHistori.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      berkas: rawBerkas.map((e) => e.toString()).toList(growable: false),
    );
  }
}

class TiketHistori {
  final String keterangan;
  final DateTime? tanggal;

  const TiketHistori({required this.keterangan, this.tanggal});

  factory TiketHistori.fromJson(Map<String, dynamic> json) => TiketHistori(
        keterangan: json['keterangan']?.toString() ?? '-',
        tanggal: DateTime.tryParse(json['tanggal']?.toString() ?? ''),
      );
}

/// Repository tiket — 1 endpoint lintas tipe, bukan 6 controller terpisah
/// seperti admin panel (lihat docs/96 §4, update 19 Agustus).
class TiketRepository {
  TiketRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<List<TiketTipe>> getTipe() async {
    final res = await _api.get<List<TiketTipe>>(
      '/tiket/tipe',
      fromData: (json) => (json as List)
          .map((e) => TiketTipe.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
    return res.data ?? const [];
  }

  Future<List<Tiket>> getList() async {
    final res = await _api.get<List<Tiket>>(
      '/tiket',
      fromData: (json) => (json as List)
          .map((e) => Tiket.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
    return res.data ?? const [];
  }

  Future<TiketDetail> getDetail(String id) async {
    final res = await _api.get<TiketDetail>(
      '/tiket/$id',
      fromData: (json) => TiketDetail.fromJson(json as Map<String, dynamic>),
    );
    return res.data!;
  }

  Future<String> create({
    required String tipe,
    required String judul,
    required String keterangan,
  }) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/tiket',
      data: {'tipe': tipe, 'judul': judul, 'keterangan': keterangan},
      fromData: (json) => json as Map<String, dynamic>,
    );
    return res.data?['id']?.toString() ?? '';
  }

  Future<void> uploadBerkas({required String tiketId, required String filePath}) {
    return _api.uploadMultipart(
      '/tiket/$tiketId/berkas',
      fields: const {},
      filePath: filePath,
      fileFieldName: 'file',
    );
  }
}
