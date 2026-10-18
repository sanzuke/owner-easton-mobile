import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:owner_easton_mobile/core/network/api_envelope.dart';
import 'package:owner_easton_mobile/core/theme/app_theme.dart';
import 'package:owner_easton_mobile/features/pbb/application/pbb_providers.dart';
import 'package:owner_easton_mobile/features/pbb/data/pbb_repository.dart';
import 'package:owner_easton_mobile/features/pbb/presentation/pbb_screen.dart';

/// Repository palsu: mencatat panggilan, hasilnya diatur per tes.
class _RepoPalsu implements PbbRepository {
  _RepoPalsu(this.data);

  Future<PbbData> Function() data;
  Future<String> Function(int id)? onHapus;
  final hapusDipanggil = <int>[];
  var muat = 0;

  @override
  Future<PbbData> getPbb() {
    muat++;
    return data();
  }

  @override
  Future<String> hapusBukti(int idDetail) {
    hapusDipanggil.add(idDetail);
    return (onHapus ?? (_) async => 'Bukti dihapus dari server.')(idDetail);
  }

  @override
  Future<Uri> tautan(int idDetail, JenisBerkasPbb jenis) => throw UnimplementedError();

  @override
  Future<String> uploadBukti(int idDetail, String filePath) => throw UnimplementedError();
}

PbbTahun _tahun(int id, int tahun, {num tagihan = 0, bool pdf = false, bool bukti = false}) => PbbTahun(
      idDetail: id,
      tahun: tahun,
      tagihan: tagihan,
      lunas: tagihan == 0,
      adaPdf: pdf,
      tglUploadPdf: pdf ? DateTime(2026, 2, 10) : null,
      adaBukti: bukti,
      tglUploadBukti: bukti ? DateTime(2026, 3, 1) : null,
    );

Future<void> _pasang(WidgetTester tester, _RepoPalsu repo) async {
  await initializeDateFormatting('id_ID');
  tester.view.physicalSize = const Size(412, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [pbbRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(theme: AppTheme.light(), home: const PbbScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('aksi tiap tahun mengikuti ketersediaan SPPT dan bukti', (tester) async {
    final repo = _RepoPalsu(() async => PbbData(
          tersedia: true,
          nop: '32.05.123',
          items: [
            _tahun(11, 2026, tagihan: 1250000, pdf: true),
            _tahun(10, 2025, bukti: true),
          ],
        ));
    await _pasang(tester, repo);

    expect(find.text('32.05.123'), findsOneWidget);
    expect(find.text('Rp1.250.000'), findsOneWidget);
    // 2026: SPPT ada -> satu "Lihat"; bukti belum -> "Unggah", tanpa Ganti/Hapus.
    // 2025: SPPT tidak ada; bukti ada -> "Lihat" + Ganti + Hapus.
    expect(find.text('Lihat'), findsNWidgets(2));
    expect(find.text('Unggah'), findsOneWidget);
    expect(find.byTooltip('Ganti bukti'), findsOneWidget);
    expect(find.byTooltip('Hapus bukti'), findsOneWidget);
    expect(find.text('Belum tersedia'), findsOneWidget);
  });

  testWidgets('unit tanpa data PBB dan daftar kosong punya pesan sendiri', (tester) async {
    await _pasang(tester, _RepoPalsu(() async => const PbbData(tersedia: false, items: [])));
    expect(find.textContaining('belum tersedia'), findsOneWidget);

    await _pasang(tester, _RepoPalsu(() async => const PbbData(tersedia: true, nop: '1', items: [])));
    expect(find.text('Belum ada rincian tagihan PBB.'), findsOneWidget);
  });

  testWidgets('gagal memuat: tombol Coba lagi memuat ulang dan data muncul', (tester) async {
    var gagal = true;
    final repo = _RepoPalsu(() async {
      if (gagal) throw const ApiException(message: 'offline');
      return PbbData(tersedia: true, nop: '1', items: [_tahun(1, 2026, tagihan: 5000)]);
    });
    await _pasang(tester, repo);
    expect(find.text('Coba lagi'), findsOneWidget);

    gagal = false;
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();

    expect(repo.muat, 2);
    expect(find.text('Rp5.000'), findsOneWidget);
  });

  testWidgets('hapus bukti: Batal tidak memanggil server', (tester) async {
    final repo = _RepoPalsu(() async => PbbData(tersedia: true, nop: '1', items: [_tahun(10, 2025, bukti: true)]));
    await _pasang(tester, repo);

    await tester.tap(find.byTooltip('Hapus bukti'));
    await tester.pumpAndSettle();
    expect(find.text('Hapus bukti bayar PBB tahun 2025?'), findsOneWidget);
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    expect(repo.hapusDipanggil, isEmpty);
  });

  testWidgets('hapus bukti: mengirim id tahun yang benar, memuat ulang, dan tombol terkunci selama proses', (tester) async {
    final selesai = Completer<String>();
    final repo = _RepoPalsu(() async => PbbData(tersedia: true, nop: '1', items: [
          _tahun(11, 2026, tagihan: 1000, bukti: true),
          _tahun(10, 2025, bukti: true),
        ]))
      ..onHapus = (_) => selesai.future;
    await _pasang(tester, repo);

    // Kartu kedua = tahun 2025 (id_detail 10).
    await tester.tap(find.byTooltip('Hapus bukti').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus'));
    await tester.pump();

    expect(repo.hapusDipanggil, [10]);
    // Selama menunggu server, tombol di kartu itu mati sehingga tidak terkirim ganda.
    final tombol = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.delete_outline_rounded).last);
    expect(tombol.onPressed, isNull);

    selesai.complete('Bukti dihapus dari server.');
    await tester.pumpAndSettle();
    expect(find.text('Bukti dihapus dari server.'), findsOneWidget);
    expect(repo.muat, 2, reason: 'daftar dimuat ulang setelah hapus');
  });

  testWidgets('hapus bukti ditolak server: pesan server tampil, bukan pesan umum', (tester) async {
    final repo = _RepoPalsu(() async => PbbData(tersedia: true, nop: '1', items: [_tahun(10, 2025, bukti: true)]))
      ..onHapus = (_) async => throw const ApiException(message: 'Bukti tidak ditemukan.', statusCode: 404);
    await _pasang(tester, repo);

    await tester.tap(find.byTooltip('Hapus bukti'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();

    expect(find.text('Bukti tidak ditemukan.'), findsOneWidget);
  });
}
