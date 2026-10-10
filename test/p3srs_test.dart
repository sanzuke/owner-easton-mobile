import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:owner_easton_mobile/features/p3srs/application/p3srs_providers.dart';
import 'package:owner_easton_mobile/features/p3srs/data/p3srs_repository.dart';
import 'package:owner_easton_mobile/features/p3srs/presentation/artikel_detail_screen.dart';
import 'package:owner_easton_mobile/features/p3srs/presentation/laporan_screen.dart';

// JSON mengikuti GET /api/v1/p3srs/* (docs/96b §9d).
void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  test('kategori: jenis laporan dibedakan dari artikel', () {
    final k = [
      {'id_kategori': 1, 'nama': 'Pengumuman', 'jenis': 'artikel', 'total': 4},
      {'id_kategori': 9, 'nama': 'Laporan', 'jenis': 'laporan', 'total': 0},
    ].map(KategoriP3srs.fromJson).toList();
    expect(k[0].laporan, isFalse);
    expect(k[0].total, 4);
    expect(k[1].laporan, isTrue);
  });

  test('halaman artikel: penanda halaman berikutnya', () {
    final h = HalamanArtikel.fromJson({
      'items': [
        {'id_post': 3, 'judul': 'Rapat', 'kategori': 'Pengumuman', 'tanggal': '2026-08-01', 'thumb_url': null},
      ],
      'pagination': {'current_page': 1, 'last_page': 2, 'total': 11},
    });
    expect(h.items.single.thumbUrl, isNull);
    expect(h.items.single.tanggal, DateTime(2026, 8, 1));
    expect(h.adaBerikutnya, isTrue);
    expect(HalamanArtikel.fromJson({'items': [], 'pagination': {'current_page': 2, 'last_page': 2}}).adaBerikutnya, isFalse);
  });

  testWidgets('detail artikel merender isi HTML (paragraf, tebal, tabel)', (tester) async {
    final detail = ArtikelDetail.fromJson({
      'id_post': 7,
      'judul': 'Pengumuman IPL',
      'kategori': 'Pengumuman',
      'tanggal': '2026-08-01',
      'banner_url': null,
      'body': '<p>Isi <b>penting</b></p><table><tr><th>Iuran</th><td>Rp 750</td></tr></table>',
      'pengunjung': 12,
    });
    await tester.pumpWidget(ProviderScope(
      overrides: [artikelDetailProvider((SumberArtikel.p3srs, 7)).overrideWith((ref) async => detail)],
      child: const MaterialApp(home: ArtikelDetailScreen(id: 7)),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Pengumuman IPL'), findsOneWidget);
    expect(find.textContaining('12 pembaca'), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().contains('Isi penting')), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().contains('Rp 750')), findsOneWidget);
  });

  testWidgets('laporan: bulan belum disetujui tampil pesan, bulan disetujui merender tabel', (tester) async {
    final now = DateTime.now();
    final bulanIni = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final prev = DateTime(now.year, now.month - 1);
    final bulanLalu = '${prev.year}-${prev.month.toString().padLeft(2, '0')}';

    await tester.pumpWidget(ProviderScope(
      overrides: [
        p3srsLaporanProvider(bulanIni).overrideWith((ref) async => LaporanP3srs(bulan: bulanIni, tersedia: false)),
        p3srsLaporanProvider(bulanLalu).overrideWith((ref) async => LaporanP3srs(
              bulan: bulanLalu,
              tersedia: true,
              html: '<h4>Laporan In Out</h4><table><tr><th>Total Pemasukan</th><td>Rp. 100</td></tr></table>',
              pengunjung: 5,
            )),
      ],
      child: const MaterialApp(home: LaporanScreen(judul: 'Laporan')),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Laporan belum tersedia untuk bulan ini.'), findsOneWidget);
    expect(tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.chevron_right_rounded)).onPressed, isNull,
        reason: 'tidak bisa maju melewati bulan berjalan');

    await tester.tap(find.byTooltip('Bulan sebelumnya'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Laporan belum tersedia untuk bulan ini.'), findsNothing);
    expect(find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().contains('Total Pemasukan')), findsOneWidget);
    expect(find.text('5 unit membaca'), findsOneWidget);
  });
}
