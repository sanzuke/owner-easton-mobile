import '../../../core/network/api_client.dart';

/// Status VA dari backend (`GET /tagihan/{id}/va`, docs/96b): `belum_dibayar`, `diproses`, `dibayar`,
/// `invoice_lunas`, `kedaluwarsa`.
enum VaStatus {
  belumDibayar('Belum dibayar'),
  diproses('Pembayaran diproses'),
  dibayar('Sudah dibayar'),
  invoiceLunas('Invoice sudah lunas'),
  kedaluwarsa('Kedaluwarsa');

  const VaStatus(this.label);
  final String label;

  static VaStatus dari(String? kode) => switch (kode) {
    'dibayar' => VaStatus.dibayar,
    'diproses' => VaStatus.diproses,
    'invoice_lunas' => VaStatus.invoiceLunas,
    'kedaluwarsa' => VaStatus.kedaluwarsa,
    _ => VaStatus.belumDibayar,
  };
}

/// Satu Virtual Account BJB milik invoice.
class VaInfo {
  final String bank;
  final String nomorVa;
  final String? namaAkun;
  final num nominal;
  final DateTime? kedaluwarsa;
  final VaStatus status;

  /// Hanya `true` bila VA belum dibayar, belum kedaluwarsa, dan invoice belum lunas.
  final bool dapatDibayar;
  final DateTime? dibayarPada;
  final num? jumlahDibayar;

  const VaInfo({
    required this.bank,
    required this.nomorVa,
    this.namaAkun,
    required this.nominal,
    this.kedaluwarsa,
    required this.status,
    required this.dapatDibayar,
    this.dibayarPada,
    this.jumlahDibayar,
  });

  factory VaInfo.fromJson(Map<String, dynamic> json) => VaInfo(
    bank: json['bank']?.toString() ?? 'Bank BJB',
    nomorVa: json['nomor_va']?.toString() ?? '',
    namaAkun: json['nama_akun']?.toString(),
    nominal: (json['nominal'] ?? 0) as num,
    kedaluwarsa: DateTime.tryParse(json['kedaluwarsa']?.toString() ?? ''),
    status: VaStatus.dari(json['status']?.toString()),
    dapatDibayar: json['dapat_dibayar'] == true,
    dibayarPada: DateTime.tryParse(json['dibayar_pada']?.toString() ?? ''),
    jumlahDibayar: json['jumlah_dibayar'] as num?,
  );
}

/// Invoice terbaru yang memegang nomor VA unit (`va_aktif_di`).
class VaInvoiceAktif {
  final String id;
  final String? nomor;

  const VaInvoiceAktif({required this.id, this.nomor});
}

/// Respons `GET /tagihan/{id}/va`: [va] null bila belum diterbitkan / unit tidak memakai VA ([alasan], [pesan]).
class VaTagihan {
  final String? nomorInvoice;
  final VaInfo? va;
  final String? alasan;
  final String pesan;

  /// Invoice yang kini memegang nomor VA unit (alasan `invoice_lama`): VA dipakai ulang tiap bulan.
  final VaInvoiceAktif? invoiceAktif;
  final List<String> langkah;
  final List<String> peringatan;

  const VaTagihan({
    this.nomorInvoice,
    this.va,
    this.alasan,
    this.pesan = '',
    this.invoiceAktif,
    this.langkah = const [],
    this.peringatan = const [],
  });

  bool get tersedia => va != null;

  factory VaTagihan.fromJson(Map<String, dynamic> json) {
    List<String> teks(dynamic v) =>
        ((v as List?) ?? const []).map((e) => e.toString()).toList(growable: false);
    final vaJson = json['va'];
    final aktif = json['va_aktif_di'];
    final petunjuk = (json['petunjuk'] as Map?)?.cast<String, dynamic>() ?? const {};
    return VaTagihan(
      nomorInvoice: (json['invoice'] as Map?)?['nomor']?.toString(),
      va: vaJson is Map<String, dynamic> ? VaInfo.fromJson(vaJson) : null,
      alasan: json['alasan']?.toString(),
      pesan: json['pesan']?.toString() ?? '',
      invoiceAktif: aktif is Map<String, dynamic>
          ? VaInvoiceAktif(
              id: aktif['id_billing']?.toString() ?? '',
              nomor: aktif['nomor']?.toString(),
            )
          : null,
      langkah: teks(petunjuk['langkah']),
      peringatan: teks(petunjuk['peringatan']),
    );
  }
}

class VaRepository {
  VaRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<VaTagihan> getVaTagihan(String idBilling) async {
    final res = await _api.get<VaTagihan>(
      '/tagihan/$idBilling/va',
      fromData: (json) => VaTagihan.fromJson(json as Map<String, dynamic>),
    );
    return res.data!;
  }
}
