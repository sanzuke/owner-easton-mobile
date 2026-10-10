import '../../../core/network/api_client.dart';

/// Berkas identitas (KTP / Kartu Keluarga) — hanya status; file dilihat lewat portal/admin.
class BerkasProfil {
  final DateTime? diunggahPada;

  const BerkasProfil({this.diunggahPada});

  static BerkasProfil? dari(dynamic json) => json is Map<String, dynamic>
      ? BerkasProfil(diunggahPada: DateTime.tryParse(json['diunggah_pada']?.toString() ?? ''))
      : null;
}

/// Data pemilik — `GET /profil` (docs/96b §8).
class Profil {
  final String nama;
  final String hp;
  final String? email;
  final String? alamat;
  final String? jenisKelamin;
  final String? tempatLahir;
  final DateTime? tanggalLahir;

  /// URL bertanda tangan 10 menit; null = belum punya foto.
  final String? fotoUrl;
  final BerkasProfil? ktp;
  final BerkasProfil? kartuKeluarga;

  const Profil({
    required this.nama,
    required this.hp,
    this.email,
    this.alamat,
    this.jenisKelamin,
    this.tempatLahir,
    this.tanggalLahir,
    this.fotoUrl,
    this.ktp,
    this.kartuKeluarga,
  });

  factory Profil.fromJson(Map<String, dynamic> json) {
    final berkas = json['berkas'];
    return Profil(
      nama: json['nama']?.toString() ?? '-',
      hp: json['hp']?.toString() ?? '-',
      email: json['email']?.toString(),
      alamat: json['alamat']?.toString(),
      jenisKelamin: json['jenis_kelamin']?.toString(),
      tempatLahir: json['tempat_lahir']?.toString(),
      tanggalLahir: _tanggalWajar(DateTime.tryParse(json['tanggal_lahir']?.toString() ?? '')),
      fotoUrl: json['foto_url']?.toString(),
      ktp: berkas is Map ? BerkasProfil.dari(berkas['ktp']) : null,
      kartuKeluarga: berkas is Map ? BerkasProfil.dari(berkas['kartu_keluarga']) : null,
    );
  }
}

/// Data lama sering berisi 0000-00-00 yang oleh Dart terbaca sebagai tahun -1; anggap kosong.
DateTime? _tanggalWajar(DateTime? t) => (t == null || t.year < 1900) ? null : t;

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

  /// `PUT /profil` membalas `data: null` — tidak ada yang dibaca dari respons; layar memuat ulang profil.
  Future<void> updateProfil({
    required String nama,
    required String hp,
    String? email,
    String? alamat,
  }) async {
    await _api.put<Object?>(
      '/profil',
      data: {'nama': nama, 'hp': hp, 'email': email, 'alamat': alamat},
    );
  }

  /// Unggah/ganti foto profil (`POST /profil/foto`, jpg/png maks 5 MB).
  Future<void> uploadFoto(String filePath) async {
    await _api.uploadMultipart<Object?>(
      '/profil/foto',
      fields: const {},
      filePath: filePath,
      fileFieldName: 'foto',
    );
  }

  /// Upload/ganti KTP atau Kartu Keluarga — `jenis`: ktp|kk (versi lama otomatis diganti).
  Future<void> uploadBerkas({required String jenis, required String filePath}) async {
    await _api.uploadMultipart<Object?>(
      '/profil/berkas',
      fields: {'jenis': jenis},
      filePath: filePath,
      fileFieldName: 'file',
    );
  }
}
