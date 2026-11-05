import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:owner_easton_mobile/core/network/api_envelope.dart';
import 'package:owner_easton_mobile/core/theme/app_theme.dart';
import 'package:owner_easton_mobile/features/qris/application/qris_providers.dart';
import 'package:owner_easton_mobile/features/qris/data/qris_repository.dart';
import 'package:owner_easton_mobile/features/qris/presentation/qris_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'support/fake_api.dart';

Map<String, dynamic> _trx({
  String status = 'pending',
  num nominal = 1500000,
  int sisa = 900,
  bool simulasi = false,
  bool sandbox = true,
  bool bisaSimulasi = false,
  Map<String, dynamic>? kwitansi,
}) => {
  'ref': 'EPR-QRIS-B1953-20261106100000-123',
  'status': status,
  'nominal': nominal,
  'qr': '000201010212EMVCO-CONTOH',
  'berlaku_sampai': '2026-11-06T10:15:00+07:00',
  'sisa_detik': sisa,
  'simulasi': simulasi,
  'sandbox': sandbox,
  'bisa_simulasi_bayar': bisaSimulasi,
  'kwitansi': ?kwitansi,
};

class _RepoPalsu implements QrisRepository {
  _RepoPalsu({this.buatHasil, this.galat, List<Map<String, dynamic>>? statusUrut, this.simulasiHasil})
    : _statusUrut = statusUrut ?? [_trx()];

  final Map<String, dynamic>? buatHasil;
  final ApiException? galat;
  final Map<String, dynamic>? simulasiHasil;
  final List<Map<String, dynamic>> _statusUrut;
  final List<num?> nominalDiminta = [];
  int statusPanggilan = 0;
  int unduhPanggilan = 0;

  @override
  Future<QrisTransaksi> buat({num? nominal}) async {
    nominalDiminta.add(nominal);
    if (galat != null) throw galat!;
    return QrisTransaksi.fromJson(buatHasil ?? _trx());
  }

  @override
  Future<QrisTransaksi> status(String ref) async {
    final json = _statusUrut[statusPanggilan < _statusUrut.length ? statusPanggilan : _statusUrut.length - 1];
    statusPanggilan++;
    return QrisTransaksi.fromJson(json);
  }

  @override
  Future<Uint8List> gambar(String ref) async {
    unduhPanggilan++;
    return pngKecil;
  }

  @override
  Future<QrisTransaksi> simulasiBayar(String ref) async => QrisTransaksi.fromJson(simulasiHasil ?? _trx(status: 'paid'));
}

class _PembagiPalsu implements PembagiQr {
  Uint8List? png;
  String? nama;

  @override
  Future<void> bagikan(Uint8List png, {required String nama}) async {
    this.png = png;
    this.nama = nama;
  }
}

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  test('QrisTransaksi membaca status, kwitansi, dan penanda mode; status tak dikenal dianggap pending', () {
    final t = QrisTransaksi.fromJson(_trx(
      status: 'paid',
      simulasi: true,
      bisaSimulasi: true,
      kwitansi: {'id_bayar': 7, 'nomor': '5/Kwt-QRIS/XI/2026', 'jumlah': 1500000, 'tanggal': '2026-11-06'},
    ));
    expect(t.status, QrisStatus.paid);
    expect(t.simulasi, isTrue);
    expect(t.bisaSimulasiBayar, isTrue);
    expect(t.kwitansi!.nomor, '5/Kwt-QRIS/XI/2026');
    expect(t.kwitansi!.jumlah, 1500000);
    expect(t.berlakuSampai!.isUtc, isTrue);
    expect(QrisStatus.dari('aneh'), QrisStatus.pending);
    expect(QrisStatus.dari('expired'), QrisStatus.expired);
  });

  test('QrisRepository: buat mengirim nominal hanya bila diisi; gambar mengembalikan bytes PNG', () async {
    final (api, adapter) = apiPalsu({
      'POST /pembayaran/qris': RespPalsu.json(201, amplop(_trx())),
      'GET /pembayaran/qris/REF1/gambar': RespPalsu.bytes(pngKecil, contentType: 'image/png'),
      'GET /pembayaran/qris/REF1': RespPalsu.json(200, amplop(_trx(status: 'expired', sisa: 0))),
    });
    final repo = QrisRepository(apiClient: api);

    await repo.buat();
    expect(adapter.terakhir('POST /pembayaran/qris')!.data, isEmpty);
    await repo.buat(nominal: 250000);
    expect(adapter.terakhir('POST /pembayaran/qris')!.data, {'nominal': 250000});
    expect(await repo.gambar('REF1'), pngKecil);
    expect((await repo.status('REF1')).status, QrisStatus.expired);
  });

  Future<(_RepoPalsu, _PembagiPalsu)> pasang(
    WidgetTester tester,
    _RepoPalsu repo, {
    Duration pantau = const Duration(hours: 1),
  }) async {
    final pembagi = _PembagiPalsu();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          qrisRepositoryProvider.overrideWithValue(repo),
          pembagiQrProvider.overrideWithValue(pembagi),
        ],
        child: MaterialApp(theme: AppTheme.light(), home: QrisScreen(intervalPantau: pantau)),
      ),
    );
    await tester.pumpAndSettle();
    return (repo, pembagi);
  }

  Future<void> tutup(WidgetTester tester) => tester.pumpWidget(const SizedBox());

  testWidgets('Buat QRIS seluruh tagihan: QR, nominal, hitung mundur, dan label sandbox tampil', (tester) async {
    final (repo, _) = await pasang(tester, _RepoPalsu());

    await tester.tap(find.text('Buat QRIS'));
    await tester.pumpAndSettle();

    expect(repo.nominalDiminta, [null]);
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('Rp1.500.000'), findsOneWidget);
    expect(find.text('Berlaku 15:00 lagi'), findsOneWidget);
    expect(find.textContaining('SANDBOX BJB'), findsOneWidget);
    expect(find.text('Simulasikan pembayaran (uji)'), findsNothing);

    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Berlaku 14:57 lagi'), findsOneWidget);
    await tutup(tester);
  });

  testWidgets('Nominal lain: kosong ditolak tanpa memanggil server; terisi dikirim sebagai angka', (tester) async {
    final (repo, _) = await pasang(tester, _RepoPalsu(buatHasil: _trx(nominal: 500000)));

    await tester.tap(find.text('Nominal lain'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buat QRIS'));
    await tester.pumpAndSettle();
    expect(find.text('Masukkan nominal pembayaran.'), findsOneWidget);
    expect(repo.nominalDiminta, isEmpty);

    await tester.enterText(find.byType(TextField), '500000');
    await tester.tap(find.text('Buat QRIS'));
    await tester.pumpAndSettle();
    expect(repo.nominalDiminta, [500000]);
    expect(find.text('Rp500.000'), findsOneWidget);
    await tutup(tester);
  });

  testWidgets('Galat dari server tampil di formulir dan formulir tetap bisa dicoba lagi', (tester) async {
    final (repo, _) = await pasang(
      tester,
      _RepoPalsu(galat: const ApiException(statusCode: 422, message: 'Tidak ada tagihan yang perlu dibayar.')),
    );

    await tester.tap(find.text('Buat QRIS'));
    await tester.pumpAndSettle();

    expect(find.text('Tidak ada tagihan yang perlu dibayar.'), findsOneWidget);
    expect(find.byType(QrImageView), findsNothing);
    expect(find.text('Buat QRIS'), findsOneWidget);
    expect(repo.nominalDiminta, hasLength(1));
  });

  testWidgets('Pemantauan: begitu server melaporkan paid, layar berubah menjadi pembayaran diterima dengan kwitansi', (tester) async {
    final repo = _RepoPalsu(statusUrut: [
      _trx(),
      _trx(
        status: 'paid',
        kwitansi: {'id_bayar': 7, 'nomor': '5/Kwt-QRIS/XI/2026', 'jumlah': 1500000, 'tanggal': '2026-11-06'},
      ),
    ]);
    await pasang(tester, repo, pantau: const Duration(seconds: 2));
    await tester.tap(find.text('Buat QRIS'));
    await tester.pumpAndSettle();

    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(find.text('Menunggu pembayaran…'), findsOneWidget, reason: 'pemeriksaan pertama masih pending');

    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(find.text('Pembayaran diterima'), findsOneWidget);
    expect(find.text('Kwitansi 5/Kwt-QRIS/XI/2026'), findsOneWidget);
    expect(find.byType(QrImageView), findsNothing);

    final dipanggil = repo.statusPanggilan;
    await tester.pump(const Duration(seconds: 10));
    expect(repo.statusPanggilan, dipanggil, reason: 'pemantauan berhenti setelah paid');
    await tutup(tester);
  });

  testWidgets('Kedaluwarsa: pesan muncul dan Buat QRIS baru kembali ke formulir', (tester) async {
    await pasang(tester, _RepoPalsu(buatHasil: _trx(sisa: 2), statusUrut: [_trx(status: 'expired', sisa: 0)]));
    await tester.tap(find.text('Buat QRIS'));
    await tester.pumpAndSettle();

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(find.text('QRIS sudah kedaluwarsa'), findsOneWidget);
    expect(find.byType(QrImageView), findsNothing);

    await tester.tap(find.text('Buat QRIS baru'));
    await tester.pumpAndSettle();
    expect(find.text('Seluruh tagihan yang belum dibayar'), findsOneWidget);
    await tutup(tester);
  });

  testWidgets('Simpan / bagikan QR mengunduh PNG dari server lalu menyerahkannya ke lembar bagikan', (tester) async {
    final (repo, pembagi) = await pasang(tester, _RepoPalsu());
    await tester.tap(find.text('Buat QRIS'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Simpan / bagikan QR'));
    await tester.pumpAndSettle();

    expect(repo.unduhPanggilan, 1);
    expect(pembagi.png, pngKecil);
    expect(pembagi.nama, 'QRIS-EPR-QRIS-B1953-20261106100000-123');
    await tutup(tester);
  });

  testWidgets('Mode uji: label simulasi dan tombol simulasi hanya bila server mengizinkan; menekannya menampilkan pembayaran diterima', (tester) async {
    await pasang(
      tester,
      _RepoPalsu(
        buatHasil: _trx(simulasi: true, bisaSimulasi: true),
        simulasiHasil: _trx(
          status: 'paid',
          simulasi: true,
          kwitansi: {'id_bayar': 9, 'nomor': '1/Kwt-QRIS/XI/2026', 'jumlah': 1500000, 'tanggal': '2026-11-06'},
        ),
      ),
    );
    await tester.tap(find.text('Buat QRIS'));
    await tester.pumpAndSettle();
    expect(find.textContaining('MODE UJI'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Simulasikan pembayaran (uji)'), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Simulasikan pembayaran (uji)'));
    await tester.pumpAndSettle();
    expect(find.text('Pembayaran diterima'), findsOneWidget);
    expect(find.text('Kwitansi 1/Kwt-QRIS/XI/2026'), findsOneWidget);
    await tutup(tester);
  });
}
