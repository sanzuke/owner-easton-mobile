import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:owner_easton_mobile/core/theme/app_theme.dart';
import 'package:owner_easton_mobile/core/theme/tampilan.dart';
import 'package:owner_easton_mobile/features/acara/application/acara_providers.dart';
import 'package:owner_easton_mobile/features/acara/data/acara_repository.dart';
import 'package:owner_easton_mobile/features/dashboard/application/dashboard_providers.dart';
import 'package:owner_easton_mobile/features/dashboard/application/tampilan_providers.dart';
import 'package:owner_easton_mobile/features/dashboard/data/dashboard_repository.dart';
import 'package:owner_easton_mobile/features/dashboard/presentation/dashboard_screen.dart';
import 'package:owner_easton_mobile/features/notifikasi/application/notifikasi_providers.dart';
import 'package:owner_easton_mobile/features/p3srs/application/p3srs_providers.dart';
import 'package:owner_easton_mobile/features/p3srs/data/p3srs_repository.dart';

class _PilihanTetap extends TampilanPilihanNotifier {
  _PilihanTetap(this._nilai);
  final TampilanPilihan _nilai;
  @override
  Future<TampilanPilihan> build() async => _nilai;
}

DashboardSummary _ringkasan({DateTime? lahir, TagihanTerbaru? tagihan, num piutang = 0}) => DashboardSummary(
      piutang: piutang,
      unitCode: 'B0341',
      tower: 'Oxford',
      namaPemilik: 'Hasan Basri, ST',
      jenisKelamin: 'Laki-laki',
      tanggalLahir: lahir,
      tagihanTerbaru: tagihan,
    );

Future<void> _pasang(
  WidgetTester tester,
  DashboardSummary s, {
  TampilanPilihan pilihan = TampilanPilihan.otomatis,
  List<ArtikelRingkas> berita = const [],
}) async {
  await initializeDateFormatting('id_ID');
  tester.view.physicalSize = const Size(412, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dashboardSummaryProvider.overrideWith((ref) async => s),
        tampilanPilihanProvider.overrideWith(() => _PilihanTetap(pilihan)),
        sekarangProvider.overrideWithValue(DateTime(2026, 10, 8, 9)),
        acaraListProvider.overrideWith((ref) async => const DaftarAcara()),
        notifikasiBelumDibacaProvider.overrideWith((ref) async => 2),
        beritaTerbaruProvider.overrideWith((ref) async => berita),
      ],
      child: MaterialApp(theme: AppTheme.light(), home: const Scaffold(body: DashboardScreen())),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final belumLunas = TagihanTerbaru(idBilling: 7, jatuhTempo: DateTime(2031, 8, 10), total: 1250000, lunas: false);

  testWidgets('Nyaman: sapaan Bapak, unit, tagihan, tombol bayar dan 6 kartu fitur', (tester) async {
    await _pasang(tester, _ringkasan(lahir: DateTime(1960, 5, 2), tagihan: belumLunas));

    expect(find.text('Selamat Pagi'), findsOneWidget);
    expect(find.text('Bapak Hasan'), findsOneWidget);
    expect(find.text('Unit B0341 · Tower Oxford'), findsOneWidget);
    expect(find.text('Rp1.250.000'), findsOneWidget);
    expect(find.text('Belum Lunas'), findsOneWidget);
    expect(find.text('Jatuh tempo 10 Agustus 2031'), findsOneWidget);
    expect(find.text('Bayar Sekarang'), findsOneWidget);
    for (final f in ['Tagihan', 'Riwayat Pembayaran', 'Cetak Invoice', 'Info PBB', 'Hubungi Pengelola', 'Pengaturan Tampilan']) {
      expect(find.text(f), findsOneWidget, reason: f);
    }
  });

  testWidgets('Modern untuk pemilik muda: sapaan Hi, label ringkas', (tester) async {
    await _pasang(tester, _ringkasan(lahir: DateTime(1995, 3, 3), tagihan: belumLunas));

    expect(find.text('SELAMAT PAGI'), findsOneWidget);
    expect(find.text('Hi, Hasan 👋'), findsOneWidget);
    expect(find.text('Riwayat Bayar'), findsOneWidget);
    expect(find.text('Tampilan'), findsOneWidget);
    expect(find.text('Riwayat Pembayaran'), findsNothing);
  });

  testWidgets('pilihan manual Nyaman mengalahkan usia muda', (tester) async {
    await _pasang(tester, _ringkasan(lahir: DateTime(1995, 3, 3), tagihan: belumLunas), pilihan: TampilanPilihan.nyaman);

    expect(find.text('Bapak Hasan'), findsOneWidget);
    expect(find.text('Riwayat Pembayaran'), findsOneWidget);
  });

  testWidgets('tagihan lunas: tanpa tombol bayar, ada pesan lunas', (tester) async {
    final lunas = TagihanTerbaru(idBilling: 7, jatuhTempo: DateTime(2031, 8, 10), total: 0, lunas: true);
    await _pasang(tester, _ringkasan(lahir: DateTime(1960, 1, 1), tagihan: lunas));

    expect(find.text('Bayar Sekarang'), findsNothing);
    expect(find.text('Lunas'), findsOneWidget);
    expect(find.text('Lunas — terima kasih'), findsOneWidget);
  });

  testWidgets('belum ada invoice: tidak ada badge maupun tombol bayar', (tester) async {
    await _pasang(tester, _ringkasan(lahir: DateTime(1960, 1, 1)));

    expect(find.text('Belum ada tagihan'), findsOneWidget);
    expect(find.text('Bayar Sekarang'), findsNothing);
    expect(find.text('Belum Lunas'), findsNothing);
  });

  testWidgets('piutang lebih besar dari tagihan terbaru ditampilkan terpisah', (tester) async {
    await _pasang(tester, _ringkasan(lahir: DateTime(1960, 1, 1), tagihan: belumLunas, piutang: 3000000));

    expect(find.text('Total belum dibayar seluruh tagihan: Rp3.000.000'), findsOneWidget);
  });

  testWidgets('berita terbaru tampil di beranda lengkap dengan tautan "Lihat semua"', (tester) async {
    final berita = [
      ArtikelRingkas(id: 93, judul: 'Upacara HUT ke-81 Kemerdekaan RI', kategori: 'Kegiatan', tanggal: DateTime(2026, 8, 17)),
      ArtikelRingkas(id: 92, judul: 'Perbaikan Wire Rope Lift', kategori: 'Pengumuman', tanggal: DateTime(2026, 8, 12)),
    ];
    await _pasang(tester, _ringkasan(lahir: DateTime(1960, 1, 1), tagihan: belumLunas), berita: berita);

    await tester.scrollUntilVisible(find.text('BERITA TERBARU'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.text('BERITA TERBARU'), findsOneWidget);
    expect(find.text('Upacara HUT ke-81 Kemerdekaan RI'), findsOneWidget);
    expect(find.text('Kegiatan'), findsOneWidget);
    expect(find.text('17 Agu 2026'), findsOneWidget);
    expect(find.text('Lihat semua'), findsOneWidget);
  });

  testWidgets('tanpa berita (kosong): bagian Berita Terbaru tidak muncul', (tester) async {
    await _pasang(tester, _ringkasan(lahir: DateTime(1960, 1, 1), tagihan: belumLunas));

    expect(find.text('BERITA TERBARU'), findsNothing);
    expect(find.text('Lihat semua'), findsNothing);
  });

}
