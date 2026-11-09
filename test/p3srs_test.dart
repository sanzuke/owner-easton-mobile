import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:owner_easton_mobile/features/p3srs/application/p3srs_providers.dart';
import 'package:owner_easton_mobile/features/p3srs/data/p3srs_repository.dart';
import 'package:owner_easton_mobile/features/p3srs/presentation/artikel_detail_screen.dart';
import 'package:owner_easton_mobile/features/p3srs/presentation/laporan_screen.dart';
import 'package:owner_easton_mobile/features/p3srs/presentation/p3srs_screen.dart';

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

  group('menu P3SRS tertata', () {
    // Respons API baru (kontrak kelompok utama/dokumen), urutan sudah final dari server.
    final responsBaru = <Map<String, dynamic>>[
      {'id_kategori': 1, 'nama': 'Informasi', 'nama_cms': 'Informasi', 'deskripsi': 'Informasi dan pengumuman pengelolaan untuk pemilik', 'ikon': 'info', 'kelompok': 'utama', 'jenis': 'artikel', 'total': 2, 'terakhir': '2026-10-05'},
      {'id_kategori': 2, 'nama': 'Laporan Kegiatan Pengelolaan', 'nama_cms': 'Laporan Kegiatan', 'deskripsi': 'Ringkasan kegiatan pengelolaan kawasan', 'ikon': 'kegiatan', 'kelompok': 'utama', 'jenis': 'artikel', 'total': 0, 'terakhir': null},
      {'id_kategori': 9, 'nama': 'Laporan Keuangan Bulanan', 'nama_cms': 'Laporan Kuangan Bulanan', 'deskripsi': 'Laporan pemasukan dan pengeluaran per bulan', 'ikon': 'keuangan', 'kelompok': 'utama', 'jenis': 'laporan', 'total': 0, 'terakhir': null},
      {'id_kategori': 10, 'nama': 'Administrasi & Legalitas', 'nama_cms': 'Administrai & Legalitas', 'deskripsi': null, 'ikon': 'dokumen', 'kelompok': 'dokumen', 'jenis': 'artikel', 'total': 3, 'terakhir': '2026-03-01'},
      {'id_kategori': 30, 'nama': 'Kategori Baru', 'nama_cms': 'Kategori Baru', 'deskripsi': '', 'ikon': 'dokumen', 'kelompok': 'dokumen', 'jenis': 'artikel', 'total': 1, 'terakhir': '2026-01-02'},
    ];
    // Respons server lama: tanpa nama_cms/deskripsi/ikon/kelompok/terakhir.
    final responsLama = <Map<String, dynamic>>[
      {'id_kategori': 1, 'nama': 'Informasi', 'jenis': 'artikel', 'total': 4},
      {'id_kategori': 9, 'nama': 'Laporan Kuangan Bulanan', 'jenis': 'laporan', 'total': 0},
    ];

    Future<void> pasang(WidgetTester tester, List<Map<String, dynamic>> json, {List<Override> extra = const []}) async {
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final kategori = json.map(KategoriP3srs.fromJson).toList();
      await tester.pumpWidget(ProviderScope(
        overrides: [p3srsKategoriProvider.overrideWith((ref) async => kategori), ...extra],
        child: const MaterialApp(home: P3srsScreen()),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    test('model: field baru opsional, tanpa field baru tidak crash', () {
      final baru = KategoriP3srs.fromJson(responsBaru[0]);
      expect(baru.kelompok, KelompokP3srs.utama);
      expect(baru.ikon, 'info');
      expect(baru.namaCms, 'Informasi');
      expect(baru.terakhir, '2026-10-05');
      expect(KategoriP3srs.fromJson(responsBaru[1]).terakhir, isNull);
      expect(KategoriP3srs.fromJson(responsBaru[4]).deskripsi, isNull, reason: 'deskripsi kosong dianggap tidak ada');

      final lama = KategoriP3srs.fromJson(responsLama[0]);
      expect(lama.kelompok, isNull);
      expect(lama.deskripsi, isNull);
      expect(lama.ikon, isNull);
      expect(lama.terakhir, isNull);
      expect(KategoriP3srs.fromJson({'id_kategori': 5, 'kelompok': 'aneh'}).kelompok, isNull);
    });

    testWidgets('respons baru: dua bagian berurutan dengan label, deskripsi, jumlah, terakhir diperbarui', (tester) async {
      await pasang(tester, responsBaru);

      expect(find.text('Informasi & Laporan'), findsOneWidget);
      expect(find.text('Dokumen Legalitas & Lainnya'), findsOneWidget);
      expect(tester.getTopLeft(find.text('Informasi & Laporan')).dy,
          lessThan(tester.getTopLeft(find.text('Dokumen Legalitas & Lainnya')).dy));

      // urutan kartu mengikuti server; label menggantikan nama CMS
      final urutan = ['Informasi', 'Laporan Kegiatan Pengelolaan', 'Laporan Keuangan Bulanan', 'Administrasi & Legalitas', 'Kategori Baru'];
      final ys = [for (final n in urutan) tester.getTopLeft(find.text(n)).dy];
      expect(ys, orderedEquals([...ys]..sort()));
      expect(find.text('Laporan Kuangan Bulanan'), findsNothing);
      expect(find.text('Administrai & Legalitas'), findsNothing);

      expect(find.text('Informasi dan pengumuman pengelolaan untuk pemilik'), findsOneWidget);
      expect(find.text('2 dokumen · Terakhir diperbarui 05 Okt 2026'), findsOneWidget);
      expect(find.text('3 dokumen · Terakhir diperbarui 01 Mar 2026'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.fact_check_outlined), findsNothing);
      expect(find.byIcon(Icons.event_note_outlined), findsOneWidget);
    });

    testWidgets('kategori tanpa terakhir/total 0 tidak error: "Belum ada dokumen"; laporan tanpa jumlah', (tester) async {
      await pasang(tester, responsBaru);

      expect(find.text('Belum ada dokumen'), findsOneWidget); // id 2, total 0, terakhir null
      expect(find.textContaining('Terakhir diperbarui'), findsNWidgets(3)); // hanya yang punya tanggal
      // kartu laporan: deskripsi saja, tanpa jumlah/terakhir
      expect(find.text('Laporan pemasukan dan pengeluaran per bulan'), findsOneWidget);
      expect(find.text('0 dokumen'), findsNothing);
    });

    testWidgets('respons lama tanpa field baru: daftar datar seperti sebelumnya', (tester) async {
      await pasang(tester, responsLama);

      expect(find.text('Informasi & Laporan'), findsNothing);
      expect(find.text('Dokumen Legalitas & Lainnya'), findsNothing);
      expect(find.text('Semua artikel'), findsOneWidget);
      expect(find.text('Informasi'), findsOneWidget);
      expect(find.text('4 artikel'), findsOneWidget);
      expect(find.text('Laporan Kuangan Bulanan'), findsOneWidget);
      expect(find.text('Laporan pemasukan & pengeluaran bulanan'), findsOneWidget);
      expect(find.byIcon(Icons.bar_chart_rounded), findsOneWidget);
      expect(find.byIcon(Icons.folder_open_outlined), findsOneWidget);
    });

    testWidgets('kategori jenis laporan tetap membuka layar laporan', (tester) async {
      final now = DateTime.now();
      final bulanIni = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final laporan = p3srsLaporanProvider(bulanIni).overrideWith((ref) async => LaporanP3srs(bulan: bulanIni, tersedia: false));

      for (final json in [responsBaru, responsLama]) {
        await pasang(tester, json, extra: [laporan]);
        await tester.tap(find.textContaining(RegExp('Laporan (Keuangan|Kuangan) Bulanan')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(LaporanScreen), findsOneWidget);
        expect(find.text('Laporan belum tersedia untuk bulan ini.'), findsOneWidget);
      }
    });
  });
}
