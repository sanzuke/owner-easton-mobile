import '../../../core/network/api_client.dart';

/// Data pemilik — `GET/PUT /profil` (lihat docs/96 update 19 Agustus).
class Profil {
  final String nama;
  final String hp;
  final String? email;
  final String? alamat;
  final String? fotoUrl;

  const Profil({
    required this.nama,
    required this.hp,
    this.email,
    this.alamat,
    this.fotoUrl,
  });

  factory Profil.fromJson(Map<String, dynamic> json) => Profil(
        nama: json['nama']?.toString() ?? '-',
        hp: json['hp']?.toString() ?? '-',
        email: json['email']?.toString(),
        alamat: json['alamat']?.toString(),
        fotoUrl: json['foto_url']?.toString() ?? json['foto']?.toString(),
      );
}

class ProfilRepository {
  ProfilRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<Profil> getProfil() async {
    final res = await _api.get<Profil>(
      '/profil',
      fromData: (json) => Profil.fromJson(json as Map<String, dynamic>),
    );
    return res.data!;
  }

  Future<Profil> updateProfil({
    required String nama,
    required String hp,
    String? email,
    String? alamat,
  }) async {
    final res = await _api.put<Profil>(
      '/profil',
      data: {'nama': nama, 'hp': hp, 'email': email, 'alamat': alamat},
      fromData: (json) => Profil.fromJson(json as Map<String, dynamic>),
    );
    return res.data!;
  }

  /// Upload/ganti KTP atau Kartu Keluarga — `jenis`: ktp|kk (lihat docs/96,
  /// endpoint POST /profil/berkas, versi lama auto soft-delete).
  Future<void> uploadBerkas({required String jenis, required String filePath}) {
    return _api.uploadMultipart(
      '/profil/berkas',
      fields: {'jenis': jenis},
      filePath: filePath,
      fileFieldName: 'file',
    );
  }
}
