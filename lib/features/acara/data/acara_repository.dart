import '../../../core/network/api_client.dart';

/// Acara/pengumuman — bagian dari 7 menu owner live di `ownerdev`
/// (lihat docs/96 §2), TAPI endpoint `/api/v1/acara` BELUM dibangun di
/// backend Laravel (baru Auth/Dashboard/Tagihan/Pembayaran/Profil/Tiket
/// yang selesai per docs/96 update 19 Agustus). Repository ini disiapkan
/// mengikuti pola/konvensi endpoint lain supaya integrasi tinggal pasang
/// begitu backend menyusul — panggilan akan gagal (404) sampai saat itu.
class Acara {
  final String id;
  final String judul;
  final DateTime? tanggal;
  final String? lokasi;
  final DateTime? batasKonfirmasi;
  final bool sudahKonfirmasi;
  final bool butuhKonfirmasi;

  const Acara({
    required this.id,
    required this.judul,
    this.tanggal,
    this.lokasi,
    this.batasKonfirmasi,
    this.sudahKonfirmasi = false,
    this.butuhKonfirmasi = false,
  });

  factory Acara.fromJson(Map<String, dynamic> json) => Acara(
        id: json['id']?.toString() ?? '',
        judul: json['judul']?.toString() ?? '-',
        tanggal: DateTime.tryParse(json['tanggal']?.toString() ?? ''),
        lokasi: json['lokasi']?.toString(),
        batasKonfirmasi: DateTime.tryParse(json['batas_konfirmasi']?.toString() ?? ''),
        sudahKonfirmasi: json['sudah_konfirmasi'] == true,
        butuhKonfirmasi: json['butuh_konfirmasi'] == true,
      );
}

class AcaraRepository {
  AcaraRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<List<Acara>> getList() async {
    final res = await _api.get<List<Acara>>(
      '/acara',
      fromData: (json) =>
          (json as List).map((e) => Acara.fromJson(e as Map<String, dynamic>)).toList(growable: false),
    );
    return res.data ?? const [];
  }

  Future<void> konfirmasiKehadiran(String id) {
    return _api.post('/acara/$id/konfirmasi');
  }
}
