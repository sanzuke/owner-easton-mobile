import 'dart:typed_data';

import '../../../core/network/api_client.dart';

/// Status transaksi QRIS dari backend (`/pembayaran/qris`, CR-08): `pending`, `expired`, `paid`.
enum QrisStatus {
  pending,
  expired,
  paid;

  static QrisStatus dari(String? kode) => switch (kode) {
    'paid' => QrisStatus.paid,
    'expired' => QrisStatus.expired,
    _ => QrisStatus.pending,
  };
}

/// Kwitansi pembayaran QRIS yang sudah tercatat.
class QrisKwitansi {
  final String nomor;
  final num jumlah;
  final String? tanggal;

  const QrisKwitansi({required this.nomor, required this.jumlah, this.tanggal});
}

/// Satu transaksi QRIS: [qr] = string yang dirender menjadi gambar QR di layar.
class QrisTransaksi {
  final String ref;
  final QrisStatus status;
  final num nominal;
  final String qr;
  final DateTime? berlakuSampai;
  final int sisaDetik;

  /// `true` = QR simulasi (tidak bisa dibayar di aplikasi bank); hanya staging.
  final bool simulasi;

  /// `true` = jalur sandbox BJB: pembayaran uji tidak memindahkan uang.
  final bool sandbox;

  /// `true` hanya di staging (tombol uji "Simulasikan pembayaran").
  final bool bisaSimulasiBayar;
  final QrisKwitansi? kwitansi;

  const QrisTransaksi({
    required this.ref,
    required this.status,
    required this.nominal,
    required this.qr,
    this.berlakuSampai,
    this.sisaDetik = 0,
    this.simulasi = false,
    this.sandbox = false,
    this.bisaSimulasiBayar = false,
    this.kwitansi,
  });

  factory QrisTransaksi.fromJson(Map<String, dynamic> json) {
    final kw = json['kwitansi'];
    return QrisTransaksi(
      ref: json['ref']?.toString() ?? '',
      status: QrisStatus.dari(json['status']?.toString()),
      nominal: (json['nominal'] ?? 0) as num,
      qr: json['qr']?.toString() ?? '',
      berlakuSampai: DateTime.tryParse(json['berlaku_sampai']?.toString() ?? ''),
      sisaDetik: ((json['sisa_detik'] ?? 0) as num).toInt(),
      simulasi: json['simulasi'] == true,
      sandbox: json['sandbox'] == true,
      bisaSimulasiBayar: json['bisa_simulasi_bayar'] == true,
      kwitansi: kw is Map<String, dynamic>
          ? QrisKwitansi(
              nomor: kw['nomor']?.toString() ?? '',
              jumlah: (kw['jumlah'] ?? 0) as num,
              tanggal: kw['tanggal']?.toString(),
            )
          : null,
    );
  }
}

class QrisRepository {
  QrisRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  /// `POST /pembayaran/qris`. [nominal] kosong = seluruh tagihan yang belum dibayar.
  Future<QrisTransaksi> buat({num? nominal}) async {
    final res = await _api.post<QrisTransaksi>(
      '/pembayaran/qris',
      data: nominal == null ? <String, dynamic>{} : {'nominal': nominal},
      fromData: (json) => QrisTransaksi.fromJson(json as Map<String, dynamic>),
    );
    return res.data!;
  }

  Future<QrisTransaksi> status(String ref) async {
    final res = await _api.get<QrisTransaksi>(
      '/pembayaran/qris/$ref',
      fromData: (json) => QrisTransaksi.fromJson(json as Map<String, dynamic>),
    );
    return res.data!;
  }

  /// QR sebagai PNG (`GET /pembayaran/qris/{ref}/gambar`) untuk disimpan/dibagikan.
  Future<Uint8List> gambar(String ref) => _api.getBytes('/pembayaran/qris/$ref/gambar');

  /// Hanya staging (`bisa_simulasi_bayar`): memposting pembayaran uji.
  Future<QrisTransaksi> simulasiBayar(String ref) async {
    final res = await _api.post<QrisTransaksi>(
      '/pembayaran/qris/$ref/simulasi-bayar',
      fromData: (json) => QrisTransaksi.fromJson(json as Map<String, dynamic>),
    );
    return res.data!;
  }
}
