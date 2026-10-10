import '../../../core/network/api_client.dart';

/// Rincian PBB satu tahun — `GET /pbb` (docs/96b §9c).
class PbbTahun {
  final int idDetail;
  final int tahun;
  final num tagihan;

  /// Sama dengan portal web: tagihan 0 = lunas.
  final bool lunas;
  final bool adaPdf;
  final DateTime? tglUploadPdf;
  final bool adaBukti;
  final DateTime? tglUploadBukti;

  const PbbTahun({
    required this.idDetail,
    required this.tahun,
    required this.tagihan,
    required this.lunas,
    required this.adaPdf,
    this.tglUploadPdf,
    required this.adaBukti,
    this.tglUploadBukti,
  });

  factory PbbTahun.fromJson(Map<String, dynamic> json) => PbbTahun(
        idDetail: int.tryParse(json['id_detail']?.toString() ?? '') ?? 0,
        tahun: int.tryParse(json['tahun']?.toString() ?? '') ?? 0,
        tagihan: num.tryParse(json['tagihan']?.toString() ?? '') ?? 0,
        lunas: json['lunas'] == true,
        adaPdf: json['ada_pdf'] == true,
        tglUploadPdf: DateTime.tryParse(json['tgl_upload_pdf']?.toString() ?? ''),
        adaBukti: json['ada_bukti'] == true,
        tglUploadBukti: DateTime.tryParse(json['tgl_upload_bukti']?.toString() ?? ''),
      );
}

class PbbData {
  /// false = unit belum punya data PBB di sistem.
  final bool tersedia;
  final String? nop;
  final List<PbbTahun> items;

  const PbbData({required this.tersedia, this.nop, required this.items});

  factory PbbData.fromJson(Map<String, dynamic> json) => PbbData(
        tersedia: json['tersedia'] == true,
        nop: json['nop']?.toString(),
        items: ((json['items'] as List?) ?? const [])
            .map((e) => PbbTahun.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
      );
}

/// Jenis berkas yang bisa dibuka: SPPT dari admin atau bukti bayar unggahan owner.
enum JenisBerkasPbb { pdf, bukti }

class PbbRepository {
  PbbRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<PbbData> getPbb() async {
    final res = await _api.get<PbbData>(
      '/pbb',
      fromData: (json) => PbbData.fromJson(json as Map<String, dynamic>),
    );
    return res.data!;
  }

  /// URL bertanda tangan berumur 10 menit untuk membuka berkas di penampil eksternal.
  Future<Uri> tautan(int idDetail, JenisBerkasPbb jenis) async {
    final res = await _api.get<String>(
      '/pbb/$idDetail/tautan',
      query: {'jenis': jenis.name},
      fromData: (json) => (json as Map<String, dynamic>)['url'].toString(),
    );
    return Uri.parse(res.data!);
  }

  /// Unggah atau ganti bukti bayar. Mengembalikan pesan sukses dari server.
  Future<String> uploadBukti(int idDetail, String filePath) async {
    final res = await _api.uploadMultipart<Object?>(
      '/pbb/$idDetail/bukti',
      fields: const {},
      filePath: filePath,
      fileFieldName: 'bukti',
    );
    return res.message;
  }

  Future<String> hapusBukti(int idDetail) async {
    final res = await _api.delete<Object?>('/pbb/$idDetail/bukti');
    return res.message;
  }
}
