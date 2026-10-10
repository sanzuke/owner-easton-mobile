import '../../../core/network/api_client.dart';
import '../../../core/pagination/daftar_berhalaman.dart';

/// Item tagihan/invoice — `GET /tagihan` (lihat docs/96 update 19 Agustus,
/// reuse BillingService::getInvoiceList).
class Tagihan {
  final String id;
  final String? nomorInvoice;
  final String? periode;
  final num total;
  final String status;

  const Tagihan({
    required this.id,
    this.nomorInvoice,
    this.periode,
    required this.total,
    required this.status,
  });

  /// Baris `GET /tagihan` (docs/96b §6): `id_billing`, `invoice`, `tanggal_terbit`, `total_piutang`
  /// (sisa yang belum dibayar; <= 0 berarti lunas).
  factory Tagihan.fromJson(Map<String, dynamic> json) {
    final sisa = (json['total_piutang'] ?? 0) as num;
    return Tagihan(
      id: json['id_billing']?.toString() ?? '',
      nomorInvoice: json['invoice']?.toString(),
      periode: json['tanggal_terbit']?.toString(),
      total: sisa,
      status: sisa <= 0 ? 'Lunas' : 'Belum lunas',
    );
  }
}

class TagihanDetail extends Tagihan {
  final List<TagihanItem> items;
  final List<TagihanPembayaran> pembayaran;

  const TagihanDetail({
    required super.id,
    super.nomorInvoice,
    super.periode,
    required super.total,
    required super.status,
    required this.items,
    this.pembayaran = const [],
  });

  /// `GET /tagihan/{id}`: `invoice`, `tanggal_terbit`, `items[{nama_tag, jumlah, status, tanggal}]`,
  /// `pembayaran[{jenis, id, nomor, tanggal, metode, jumlah, cetak_url}]`.
  /// Status item 1 = tagihan, 2/3 = pembayaran (mengurangi); total = tagihan - pembayaran.
  factory TagihanDetail.fromJson(Map<String, dynamic> json, String id) {
    final rawItems = (json['items'] as List?) ?? const [];
    final items = rawItems
        .map((e) => TagihanItem.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    final pembayaran = ((json['pembayaran'] as List?) ?? const [])
        .map((e) => TagihanPembayaran.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    final sisa = items.fold<num>(
      0,
      (a, i) =>
          a +
          (i.status == 1
              ? i.nominal
              : (i.status == 2 || i.status == 3)
              ? -i.nominal
              : 0),
    );
    return TagihanDetail(
      id: id,
      nomorInvoice: json['invoice']?.toString(),
      periode: json['tanggal_terbit']?.toString(),
      total: sisa,
      status: sisa <= 0 ? 'Lunas' : 'Belum lunas',
      items: items,
      pembayaran: pembayaran,
    );
  }
}

/// Satu kwitansi (`payment`) atau credit note (`cn`) yang melunasi invoice. [jumlah] = porsi invoice ini,
/// [cetakUrl] hanya ada untuk kwitansi (tautan bertanda tangan, dibuka di browser).
class TagihanPembayaran {
  final bool creditNote;
  final String nomor;
  final DateTime? tanggal;
  final String? metode;
  final num jumlah;
  final String? cetakUrl;

  const TagihanPembayaran({
    required this.creditNote,
    required this.nomor,
    this.tanggal,
    this.metode,
    required this.jumlah,
    this.cetakUrl,
  });

  factory TagihanPembayaran.fromJson(Map<String, dynamic> json) =>
      TagihanPembayaran(
        creditNote: json['jenis'] == 'cn',
        nomor: json['nomor']?.toString() ?? '-',
        tanggal: DateTime.tryParse(json['tanggal']?.toString() ?? ''),
        metode: json['metode']?.toString(),
        jumlah: (json['jumlah'] ?? 0) as num,
        cetakUrl: json['cetak_url']?.toString(),
      );
}

class TagihanItem {
  final String nama;
  final num nominal;
  final int status;

  const TagihanItem({
    required this.nama,
    required this.nominal,
    this.status = 1,
  });

  factory TagihanItem.fromJson(Map<String, dynamic> json) => TagihanItem(
    nama: json['nama_tag']?.toString() ?? '-',
    nominal: (json['jumlah'] ?? 0) as num,
    status: (json['status'] as num?)?.toInt() ?? 1,
  );
}

class TagihanRepository {
  TagihanRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  static const _perHalaman = 15;

  /// Satu halaman `GET /tagihan` (terbit terbaru dulu), opsional dibatasi [periode] (tanggal terbit, inklusif).
  Future<Halaman<Tagihan>> getHalaman(int halaman, Periode? periode) async {
    final res = await _api.get<Halaman<Tagihan>>(
      '/tagihan',
      query: {'page': halaman, 'per_page': _perHalaman, ...?periode?.query},
      fromData: (json) => Halaman.dariJson(json, Tagihan.fromJson),
    );
    return res.data ?? const Halaman([], 1);
  }

  Future<TagihanDetail> getDetail(String id) async {
    final res = await _api.get<TagihanDetail>(
      '/tagihan/$id',
      fromData: (json) =>
          TagihanDetail.fromJson(json as Map<String, dynamic>, id),
    );
    return res.data!;
  }
}
