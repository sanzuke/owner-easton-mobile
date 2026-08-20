import '../../../core/network/api_client.dart';

/// Notifikasi — muncul di setiap layar (ikon lonceng) pada desain resmi,
/// TAPI endpoint `/api/v1/notifikasi` BELUM dibangun di backend (belum
/// disebut sama sekali di docs/96 — hanya FCM push disebut sebagai item
/// "belum" berkali-kali). Repository ini disiapkan mengikuti konvensi
/// endpoint lain; panggilan akan gagal (404) sampai backend menyusul.
class Notifikasi {
  final String id;
  final String judul;
  final String pesan;
  final DateTime? waktu;
  final bool sudahDibaca;

  const Notifikasi({
    required this.id,
    required this.judul,
    required this.pesan,
    this.waktu,
    this.sudahDibaca = false,
  });

  factory Notifikasi.fromJson(Map<String, dynamic> json) => Notifikasi(
        id: json['id']?.toString() ?? '',
        judul: json['judul']?.toString() ?? '-',
        pesan: json['pesan']?.toString() ?? json['keterangan']?.toString() ?? '',
        waktu: DateTime.tryParse(json['waktu']?.toString() ?? ''),
        sudahDibaca: json['sudah_dibaca'] == true,
      );
}

class NotifikasiRepository {
  NotifikasiRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<List<Notifikasi>> getList() async {
    final res = await _api.get<List<Notifikasi>>(
      '/notifikasi',
      fromData: (json) => (json as List)
          .map((e) => Notifikasi.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
    return res.data ?? const [];
  }
}
