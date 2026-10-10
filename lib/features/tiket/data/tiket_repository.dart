import '../../../core/network/api_client.dart';

/// Tipe tiket — `GET /tiket/tipe` (`[{id, nama}]`: Defect, Reject, Fitting Out, General,
/// Work Order, Access Card — dari tabel `tiket_tipe`, lihat docs/96b §9).
class TiketTipe {
  final String id;
  final String nama;

  const TiketTipe({required this.id, required this.nama});

  factory TiketTipe.fromJson(Map<String, dynamic> json) => TiketTipe(
        id: json['id']?.toString() ?? '',
        nama: json['nama']?.toString() ?? '-',
      );
}

/// Satu baris `GET /tiket` — `tipe` sudah berupa nama (bukan id), `status` sudah berupa label.
class Tiket {
  final String id;
  final String noForm;
  final String keterangan;
  final String tipe;
  final String status;
  final DateTime? tanggal;

  const Tiket({
    required this.id,
    required this.noForm,
    required this.keterangan,
    required this.tipe,
    required this.status,
    this.tanggal,
  });

  factory Tiket.fromJson(Map<String, dynamic> json) => Tiket(
        id: json['id_tiket']?.toString() ?? '',
        noForm: json['no_form']?.toString() ?? '',
        keterangan: json['keterangan']?.toString() ?? '-',
        tipe: json['tipe']?.toString() ?? '-',
        status: json['status']?.toString() ?? '-',
        tanggal: DateTime.tryParse(json['tanggal']?.toString() ?? ''),
      );
}

class TiketBerkas {
  final String nama;
  final String file;

  const TiketBerkas({required this.nama, required this.file});

  factory TiketBerkas.fromJson(Map<String, dynamic> json) => TiketBerkas(
        nama: json['nama']?.toString() ?? 'Lampiran',
        file: json['file']?.toString() ?? '',
      );
}

class TiketTimeline {
  final String keterangan;
  final DateTime? tanggal;

  const TiketTimeline({required this.keterangan, this.tanggal});

  factory TiketTimeline.fromJson(Map<String, dynamic> json) => TiketTimeline(
        keterangan: json['keterangan']?.toString() ?? '-',
        tanggal: DateTime.tryParse(json['tanggal']?.toString() ?? ''),
      );
}

/// `GET /tiket/{id}` — tidak membawa nama tipe; layar detail memakai tipe dari daftar.
class TiketDetail {
  final String id;
  final String noForm;
  final String keterangan;
  final String status;
  final DateTime? tanggal;
  final List<TiketTimeline> timeline;
  final List<TiketBerkas> berkas;

  const TiketDetail({
    required this.id,
    required this.noForm,
    required this.keterangan,
    required this.status,
    this.tanggal,
    required this.timeline,
    required this.berkas,
  });

  factory TiketDetail.fromJson(Map<String, dynamic> json) => TiketDetail(
        id: json['id_tiket']?.toString() ?? '',
        noForm: json['no_form']?.toString() ?? '',
        keterangan: json['keterangan']?.toString() ?? '-',
        status: json['status']?.toString() ?? '-',
        tanggal: DateTime.tryParse(json['tanggal']?.toString() ?? ''),
        timeline: ((json['timeline'] as List?) ?? const [])
            .map((e) => TiketTimeline.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
        berkas: ((json['berkas'] as List?) ?? const [])
            .map((e) => TiketBerkas.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
      );
}

/// Repository tiket — 1 endpoint lintas tipe, bukan 6 controller terpisah
/// seperti admin panel (lihat docs/96 §4, update 19 Agustus).
class TiketRepository {
  TiketRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  static const _perHalaman = 50; // batas atas `per_page` di API

  Future<List<TiketTipe>> getTipe() async {
    final res = await _api.get<List<TiketTipe>>(
      '/tiket/tipe',
      fromData: (json) => (json as List)
          .map((e) => TiketTipe.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
    return res.data ?? const [];
  }

  /// Semua tiket unit — API berhalaman (`{items, pagination}`), semua halaman digabung.
  Future<List<Tiket>> getList() async {
    final hasil = <Tiket>[];
    var halaman = 1;
    var terakhir = 1;
    do {
      final res = await _api.get<Map<String, dynamic>>(
        '/tiket',
        query: {'per_page': _perHalaman, 'page': halaman},
        fromData: (json) => json as Map<String, dynamic>,
      );
      final data = res.data ?? const <String, dynamic>{};
      hasil.addAll(((data['items'] as List?) ?? const [])
          .map((e) => Tiket.fromJson(e as Map<String, dynamic>)));
      terakhir = (data['pagination']?['last_page'] as num?)?.toInt() ?? 1;
      halaman++;
    } while (halaman <= terakhir);
    return hasil;
  }

  Future<TiketDetail> getDetail(String id) async {
    final res = await _api.get<TiketDetail>(
      '/tiket/$id',
      fromData: (json) => TiketDetail.fromJson(json as Map<String, dynamic>),
    );
    return res.data!;
  }

  /// `POST /tiket` — body `{tipe: id tipe, ket}`; `kontak` opsional (default HP pemilik).
  Future<String> create({required String tipe, required String keterangan}) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/tiket',
      data: {'tipe': int.parse(tipe), 'ket': keterangan},
      fromData: (json) => json as Map<String, dynamic>,
    );
    return res.data?['id_tiket']?.toString() ?? '';
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
