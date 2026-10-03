import '../../../core/network/api_client.dart';

/// Inbox notifikasi (docs/96b §11b). Inbox adalah sumber kebenaran; push FCM
/// hanya pemicu, jadi daftar ini WAJIB dimuat saat layar dibuka.
class Notifikasi {
  final int id;
  final String judul;
  final String pesan;
  final String tipe;
  final Map<String, dynamic>? data;
  final DateTime? waktu;
  final bool sudahDibaca;

  const Notifikasi({
    required this.id,
    required this.judul,
    required this.pesan,
    this.tipe = 'umum',
    this.data,
    this.waktu,
    this.sudahDibaca = false,
  });

  factory Notifikasi.fromJson(Map<String, dynamic> json) => Notifikasi(
        id: (json['id'] as num?)?.toInt() ?? 0,
        judul: json['judul']?.toString() ?? '-',
        pesan: json['isi']?.toString() ?? '',
        tipe: json['tipe']?.toString() ?? 'umum',
        data: (json['data'] as Map?)?.cast<String, dynamic>(),
        waktu: DateTime.tryParse(json['waktu']?.toString() ?? ''),
        sudahDibaca: json['dibaca'] == true,
      );
}

class NotifikasiPage {
  final List<Notifikasi> items;
  final int belumDibaca;

  const NotifikasiPage({required this.items, required this.belumDibaca});

  factory NotifikasiPage.fromJson(Map<String, dynamic> json) => NotifikasiPage(
        items: ((json['items'] as List?) ?? const [])
            .map((e) => Notifikasi.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
        belumDibaca: (json['belum_dibaca'] as num?)?.toInt() ?? 0,
      );
}

class NotifikasiRepository {
  NotifikasiRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<NotifikasiPage> getPage({int page = 1}) async {
    final res = await _api.get<NotifikasiPage>(
      '/notifikasi',
      query: {'page': page},
      fromData: (json) => NotifikasiPage.fromJson(json as Map<String, dynamic>),
    );
    return res.data ?? const NotifikasiPage(items: [], belumDibaca: 0);
  }

  Future<void> tandaiDibaca(int id) => _api.post<void>('/notifikasi/$id/baca');

  Future<void> tandaiSemuaDibaca() => _api.post<void>('/notifikasi/baca-semua');

  /// Daftarkan token FCM perangkat ini ke backend (`POST /device-token`).
  Future<void> daftarkanPerangkat({
    required String token,
    required String platform,
    String? appVersion,
  }) =>
      _api.post<void>('/device-token', data: {
        'token': token,
        'platform': platform,
        if (appVersion != null) 'app_version': appVersion,
      });

  Future<void> lepasPerangkat(String token) =>
      _api.delete<void>('/device-token', data: {'token': token});
}
