import '../../../core/network/api_client.dart';

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

  factory Tagihan.fromJson(Map<String, dynamic> json) => Tagihan(
        id: json['id']?.toString() ?? json['id_invoice']?.toString() ?? '',
        nomorInvoice: json['nomor_invoice']?.toString() ?? json['no_invoice']?.toString(),
        periode: json['periode']?.toString(),
        total: (json['total'] ?? json['nominal'] ?? 0) as num,
        status: json['status']?.toString() ?? 'unknown',
      );
}

class TagihanDetail extends Tagihan {
  final List<TagihanItem> items;

  const TagihanDetail({
    required super.id,
    super.nomorInvoice,
    super.periode,
    required super.total,
    required super.status,
    required this.items,
  });

  factory TagihanDetail.fromJson(Map<String, dynamic> json) {
    final base = Tagihan.fromJson(json);
    final rawItems = (json['items'] as List?) ?? const [];
    return TagihanDetail(
      id: base.id,
      nomorInvoice: base.nomorInvoice,
      periode: base.periode,
      total: base.total,
      status: base.status,
      items: rawItems
          .map((e) => TagihanItem.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}

class TagihanItem {
  final String nama;
  final num nominal;

  const TagihanItem({required this.nama, required this.nominal});

  factory TagihanItem.fromJson(Map<String, dynamic> json) => TagihanItem(
        nama: json['nama']?.toString() ?? json['keterangan']?.toString() ?? '-',
        nominal: (json['nominal'] ?? json['total'] ?? 0) as num,
      );
}

class TagihanRepository {
  TagihanRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<List<Tagihan>> getList() async {
    final res = await _api.get<List<Tagihan>>(
      '/tagihan',
      fromData: (json) => (json as List)
          .map((e) => Tagihan.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
    return res.data ?? const [];
  }

  Future<TagihanDetail> getDetail(String id) async {
    final res = await _api.get<TagihanDetail>(
      '/tagihan/$id',
      fromData: (json) => TagihanDetail.fromJson(json as Map<String, dynamic>),
    );
    return res.data!;
  }
}
