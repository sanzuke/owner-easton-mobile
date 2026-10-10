import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';

/// Acara, RSVP & Voting — kontrak `docs/96b` §11c (`/api/v1/acara...`).
/// Identitas unit diambil dari token (id_bast) di backend.

DateTime? _tgl(Object? v) {
  final s = v?.toString() ?? '';
  if (s.isEmpty || s.startsWith('0000')) return null;
  return DateTime.tryParse(s.replaceFirst(' ', 'T'));
}

/// Ringkasan satu acara (item `aktif`/`riwayat` pada `GET /acara`).
class Acara {
  final String kode;
  final String nama;
  final String deskripsi;
  final String lokasi;
  final String? linkOnline;
  final DateTime? tglMulai;
  final DateTime? tglSelesai;
  final DateTime? batasRsvp;
  final int status; // 1 aktif, 2 selesai
  final String? kehadiran; // online|pemilik|dikuasakan, null = belum RSVP
  final String? mode;

  const Acara({
    required this.kode,
    required this.nama,
    this.deskripsi = '',
    this.lokasi = '',
    this.linkOnline,
    this.tglMulai,
    this.tglSelesai,
    this.batasRsvp,
    this.status = 1,
    this.kehadiran,
    this.mode,
  });

  bool get sudahRsvp => kehadiran != null && kehadiran!.isNotEmpty;

  Acara conKehadiran(String? k) => Acara(
        kode: kode,
        nama: nama,
        deskripsi: deskripsi,
        lokasi: lokasi,
        linkOnline: linkOnline,
        tglMulai: tglMulai,
        tglSelesai: tglSelesai,
        batasRsvp: batasRsvp,
        status: status,
        kehadiran: k,
        mode: mode,
      );

  factory Acara.fromJson(Map<String, dynamic> j) => Acara(
        kode: j['kode']?.toString() ?? '',
        nama: j['nama']?.toString() ?? '-',
        deskripsi: j['deskripsi']?.toString() ?? '',
        lokasi: j['lokasi']?.toString() ?? '',
        linkOnline: (j['link_online']?.toString().isNotEmpty ?? false) ? j['link_online'].toString() : null,
        tglMulai: _tgl(j['tgl_mulai']),
        tglSelesai: _tgl(j['tgl_selesai']),
        batasRsvp: _tgl(j['batas_rsvp']),
        status: int.tryParse(j['status']?.toString() ?? '') ?? 1,
        kehadiran: j['kehadiran']?.toString(),
        mode: j['mode']?.toString(),
      );
}

class DaftarAcara {
  final List<Acara> aktif;
  final List<Acara> riwayat;
  const DaftarAcara({this.aktif = const [], this.riwayat = const []});

  factory DaftarAcara.fromJson(Map<String, dynamic> j) => DaftarAcara(
        aktif: _list(j['aktif']),
        riwayat: _list(j['riwayat']),
      );

  static List<Acara> _list(Object? v) =>
      (v as List? ?? const []).map((e) => Acara.fromJson(e as Map<String, dynamic>)).toList(growable: false);
}

/// RSVP unit ini pada satu acara (`peserta` di `GET /acara/{kode}`).
class PesertaAcara {
  final String kehadiran;
  final String mode;
  final String namaHadir;
  final String namaWakil;
  final bool adaSuratKuasa;
  final bool adaKtpWakil;
  final bool adaSuratIzinHuni;
  final bool punyaQr;
  final bool sudahCheckin;

  const PesertaAcara({
    required this.kehadiran,
    required this.mode,
    this.namaHadir = '',
    this.namaWakil = '',
    this.adaSuratKuasa = false,
    this.adaKtpWakil = false,
    this.adaSuratIzinHuni = false,
    this.punyaQr = false,
    this.sudahCheckin = false,
  });

  factory PesertaAcara.fromJson(Map<String, dynamic> j) => PesertaAcara(
        kehadiran: j['kehadiran']?.toString() ?? '',
        mode: j['mode']?.toString() ?? '',
        namaHadir: j['nama_hadir']?.toString() ?? '',
        namaWakil: j['nama_wakil']?.toString() ?? '',
        adaSuratKuasa: j['ada_surat_kuasa'] == true,
        adaKtpWakil: j['ada_ktp_wakil'] == true,
        adaSuratIzinHuni: j['ada_surat_izin_huni'] == true,
        punyaQr: j['punya_qr'] == true,
        sudahCheckin: (int.tryParse(j['checkin_status']?.toString() ?? '') ?? 0) > 0,
      );
}

class DetailAcara {
  final Acara acara;
  final String? linkMaps;
  final String deskripsiMateri;
  final bool adaUndangan;
  final bool adaTatib;
  final bool adaMateri;
  final PesertaAcara? peserta;
  final bool bisaRsvp;
  final bool sudahCheckin;
  final bool adaVoting;

  const DetailAcara({
    required this.acara,
    this.linkMaps,
    this.deskripsiMateri = '',
    this.adaUndangan = false,
    this.adaTatib = false,
    this.adaMateri = false,
    this.peserta,
    this.bisaRsvp = false,
    this.sudahCheckin = false,
    this.adaVoting = false,
  });

  factory DetailAcara.fromJson(Map<String, dynamic> j) {
    final dok = (j['dokumen'] as Map?)?.cast<String, dynamic>() ?? const {};
    final p = j['peserta'];
    return DetailAcara(
      acara: Acara.fromJson(j).conKehadiran(p is Map ? p['kehadiran']?.toString() : null),
      linkMaps: (j['link_maps']?.toString().isNotEmpty ?? false) ? j['link_maps'].toString() : null,
      deskripsiMateri: j['deskripsi_materi']?.toString() ?? '',
      adaUndangan: dok['undangan'] == true,
      adaTatib: dok['tatib'] == true,
      adaMateri: dok['materi'] == true,
      peserta: p is Map ? PesertaAcara.fromJson(p.cast<String, dynamic>()) : null,
      bisaRsvp: j['bisa_rsvp'] == true,
      sudahCheckin: j['sudah_checkin'] == true,
      adaVoting: j['ada_voting'] == true,
    );
  }
}

class QrKehadiran {
  final String token;
  final String kodeAcara;
  final String kodeUnit;
  final bool sudahCheckin;
  const QrKehadiran({required this.token, required this.kodeAcara, required this.kodeUnit, this.sudahCheckin = false});

  factory QrKehadiran.fromJson(Map<String, dynamic> j) => QrKehadiran(
        token: j['qr_token']?.toString() ?? '',
        kodeAcara: j['kode_acara']?.toString() ?? '',
        kodeUnit: j['kode_unit']?.toString() ?? '',
        sudahCheckin: (int.tryParse(j['checkin_status']?.toString() ?? '') ?? 0) > 0,
      );
}

class OpsiVoting {
  final int id;
  final String teks;
  const OpsiVoting({required this.id, required this.teks});

  factory OpsiVoting.fromJson(Map<String, dynamic> j) =>
      OpsiVoting(id: int.tryParse(j['id_opsi']?.toString() ?? '') ?? 0, teks: j['teks_opsi']?.toString() ?? '');
}

class Voting {
  final int id;
  final String pertanyaan;
  final bool multi; // tipe selain 'single'
  final bool buka;
  final String? labelTutup;
  final String? alasanTutup;
  final bool tampilHasil;
  final bool sudah;
  final List<int> pilihan;
  final List<OpsiVoting> opsi;

  const Voting({
    required this.id,
    required this.pertanyaan,
    this.multi = false,
    this.buka = false,
    this.labelTutup,
    this.alasanTutup,
    this.tampilHasil = false,
    this.sudah = false,
    this.pilihan = const [],
    this.opsi = const [],
  });

  factory Voting.fromJson(Map<String, dynamic> j) => Voting(
        id: int.tryParse(j['id_voting']?.toString() ?? '') ?? 0,
        pertanyaan: j['pertanyaan']?.toString() ?? '',
        multi: (j['tipe']?.toString() ?? 'single') != 'single',
        buka: j['buka'] == true,
        labelTutup: j['label_tutup']?.toString(),
        alasanTutup: j['alasan_tutup']?.toString(),
        tampilHasil: j['tampil_hasil'] == true,
        sudah: j['sudah'] == true,
        pilihan: (j['pilihan'] as List? ?? const []).map((e) => int.tryParse(e.toString()) ?? 0).toList(growable: false),
        opsi: (j['opsi'] as List? ?? const [])
            .map((e) => OpsiVoting.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
      );
}

class DaftarVoting {
  final bool sudahRsvp;
  final List<Voting> votings;
  const DaftarVoting({this.sudahRsvp = false, this.votings = const []});

  factory DaftarVoting.fromJson(Map<String, dynamic> j) => DaftarVoting(
        sudahRsvp: j['sudah_rsvp'] == true,
        votings: (j['votings'] as List? ?? const [])
            .map((e) => Voting.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
      );
}

class HasilVoting {
  final int pemilih;
  final List<({String teks, int jml})> opsi;
  const HasilVoting({this.pemilih = 0, this.opsi = const []});

  factory HasilVoting.fromJson(Map<String, dynamic> j) => HasilVoting(
        pemilih: int.tryParse(j['pemilih']?.toString() ?? '') ?? 0,
        opsi: (j['opsi'] as List? ?? const [])
            .map((e) => (
                  teks: (e as Map)['teks_opsi']?.toString() ?? '',
                  jml: int.tryParse(e['jml']?.toString() ?? '') ?? 0,
                ))
            .toList(growable: false),
      );
}

class AcaraRepository {
  AcaraRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<DaftarAcara> getList() async {
    final res = await _api.get<DaftarAcara>(
      '/acara',
      fromData: (json) => DaftarAcara.fromJson(json as Map<String, dynamic>),
    );
    return res.data ?? const DaftarAcara();
  }

  Future<DetailAcara> getDetail(String kode) async {
    final res = await _api.get<DetailAcara>(
      '/acara/$kode',
      fromData: (json) => DetailAcara.fromJson(json as Map<String, dynamic>),
    );
    return res.data!;
  }

  Future<QrKehadiran> getQr(String kode) async {
    final res = await _api.get<QrKehadiran>(
      '/acara/$kode/qr',
      fromData: (json) => QrKehadiran.fromJson(json as Map<String, dynamic>),
    );
    return res.data!;
  }

  /// `POST /acara/{kode}/rsvp` (multipart). [berkas]: field (`surat_kuasa`,
  /// `ktp_wakil`, `surat_izin_huni`) -> path berkas lokal; hanya untuk dikuasakan.
  Future<String> rsvp(
    String kode, {
    required String cara,
    String? offlineTipe,
    String namaHadir = '',
    String namaWakilKuasa = '',
    Map<String, String> berkas = const {},
  }) async {
    final form = FormData.fromMap({
      'cara': cara,
      'offline_tipe': ?offlineTipe,
      'nama_hadir': namaHadir,
      if (offlineTipe == 'dikuasakan') 'nama_wakil_kuasa': namaWakilKuasa,
      for (final e in berkas.entries) e.key: await MultipartFile.fromFile(e.value),
    });
    final res = await _api.post<Object?>('/acara/$kode/rsvp', data: form);
    return res.message;
  }

  Future<DaftarVoting> getVoting(String kode) async {
    final res = await _api.get<DaftarVoting>(
      '/acara/$kode/voting',
      fromData: (json) => DaftarVoting.fromJson(json as Map<String, dynamic>),
    );
    return res.data ?? const DaftarVoting();
  }

  Future<String> kirimSuara(int idVoting, List<int> opsi) async {
    final res = await _api.post<Object?>(
      '/acara/voting/$idVoting/suara',
      data: {'opsi': opsi},
    );
    return res.message;
  }

  Future<HasilVoting> getHasil(int idVoting) async {
    final res = await _api.get<HasilVoting>(
      '/acara/voting/$idVoting/hasil',
      fromData: (json) => HasilVoting.fromJson(json as Map<String, dynamic>),
    );
    return res.data ?? const HasilVoting();
  }
}
