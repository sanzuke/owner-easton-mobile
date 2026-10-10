import 'package:flutter/material.dart';
import 'package:owner_easton_mobile/core/theme/app_colors.dart';
import 'package:owner_easton_mobile/core/theme/app_theme.dart';
import 'package:owner_easton_mobile/core/widgets/status_badge.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:owner_easton_mobile/features/tagihan/application/tagihan_providers.dart';
import 'package:owner_easton_mobile/features/tagihan/data/tagihan_repository.dart';
import 'package:owner_easton_mobile/core/pagination/daftar_berhalaman.dart';
import 'package:owner_easton_mobile/features/tagihan/presentation/tagihan_detail_screen.dart';
import 'package:owner_easton_mobile/features/tagihan/presentation/tagihan_list_screen.dart';

Map<String, dynamic> _json({List<Map<String, dynamic>>? pembayaran}) => {
  'invoice': 'INV/EPR-IPL/3767/VII/2026',
  'tanggal_terbit': '2026-07-01',
  'unit': 'B0648',
  'items': [
    {
      'nama_tag': 'IPL',
      'jumlah': 1219500.0,
      'status': 1,
      'tanggal': '2026-07-01',
    },
    {
      'nama_tag': 'IPL',
      'jumlah': 1219500.0,
      'status': 2,
      'tanggal': '2026-07-05',
    },
  ],
  'pembayaran': ?pembayaran,
};

const _kwitansi = {
  'jenis': 'payment',
  'id': 8801,
  'nomor': '1893/Kwt-INV/V/2026',
  'tanggal': '2026-04-25',
  'metode': 'BANK BJB',
  'jumlah': 1219500.0,
  'cetak_url': 'https://bms2.example/share/ipl?t=abc',
};
const _cn = {
  'jenis': 'cn',
  'id': 7,
  'nomor': 'CN/1',
  'tanggal': '2026-05-01',
  'metode': null,
  'jumlah': 50000.0,
  'cetak_url': null,
};

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));
  tagihanTerakhirTest();
  statusBadgeTest();

  test(
    'TagihanDetail membaca pembayaran; server lama tanpa field pembayaran tetap terbaca',
    () {
      final d = TagihanDetail.fromJson(
        _json(pembayaran: [_kwitansi, _cn]),
        '1',
      );
      expect(d.pembayaran, hasLength(2));
      expect(d.pembayaran[0].creditNote, isFalse);
      expect(d.pembayaran[0].tanggal, DateTime(2026, 4, 25));
      expect(d.pembayaran[0].cetakUrl, contains('share/ipl'));
      expect(d.pembayaran[1].creditNote, isTrue);
      expect(d.pembayaran[1].cetakUrl, isNull);
      expect(d.pembayaran[1].metode, isNull);

      expect(TagihanDetail.fromJson(_json(), '1').pembayaran, isEmpty);
    },
  );

  Future<void> pasang(WidgetTester tester, TagihanDetail d) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [tagihanDetailProvider('1').overrideWith((ref) async => d)],
        child: const MaterialApp(home: TagihanDetailScreen(id: '1')),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Riwayat Pembayaran: tombol Print hanya untuk kwitansi, credit note tanpa tombol',
    (tester) async {
      await pasang(
        tester,
        TagihanDetail.fromJson(_json(pembayaran: [_kwitansi, _cn]), '1'),
      );

      expect(find.text('Riwayat Pembayaran'), findsOneWidget);
      expect(find.text('1893/Kwt-INV/V/2026'), findsOneWidget);
      expect(find.text('CN/1'), findsOneWidget);
      expect(find.text('Print'), findsOneWidget);
    },
  );

  testWidgets('invoice belum dibayar: bagian Riwayat Pembayaran tidak muncul', (
    tester,
  ) async {
    await pasang(tester, TagihanDetail.fromJson(_json(pembayaran: []), '1'));

    expect(find.text('Riwayat Pembayaran'), findsNothing);
    expect(find.text('Print'), findsNothing);
  });

  testWidgets('status detail tampil sebagai badge berwarna: Lunas hijau, Belum lunas merah muda', (
    tester,
  ) async {
    Color warna(String teks) => tester.widget<Text>(find.text(teks)).style!.color!;

    await pasang(tester, TagihanDetail.fromJson(_json(), '1')); // tagihan 1.219.500 dibayar penuh
    expect(warna('LUNAS'), AppColors.paymentBadgeFg);

    final belum = _json()..['items'] = [(_json()['items'] as List).first];
    await tester.pumpWidget(const SizedBox()); // paksa layar dibangun ulang
    await pasang(tester, TagihanDetail.fromJson(belum, '1'));
    expect(warna('BELUM LUNAS'), AppColors.invoiceBadgeFg);
  });
}

class _RepoTagihanPalsu implements TagihanRepository {
  @override
  Future<Halaman<Tagihan>> getHalaman(int halaman, Periode? periode) async =>
      const Halaman([
        Tagihan(
          id: '9',
          nomorInvoice: 'INV/9',
          periode: '2026-07-01',
          total: 500000,
          status: 'Belum lunas',
        ),
      ], 1);

  @override
  Future<TagihanDetail> getDetail(String id) async =>
      TagihanDetail.fromJson(_json(pembayaran: [_kwitansi]), id);
}

void tagihanTerakhirTest() {
  testWidgets('kartu Tagihan Terakhir tetap bisa diketuk setelah pindah ELECTRICITY lalu INVOICE (tema asli)', (
    tester,
  ) async {
    // Tema asli penting: ia memberi FilledButton minimumSize lebar tak hingga; tombol di dalam Row tanpa
    // override merusak layout seluruh daftar (data hilang, tidak bisa diketuk).
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tagihanRepositoryProvider.overrideWithValue(_RepoTagihanPalsu()),
        ],
        child: MaterialApp(theme: AppTheme.light(), home: const TagihanListScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('INV/9 · 2026-07-01'), findsOneWidget);

    await tester.tap(find.text('ELECTRICITY'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('INVOICE'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tagihan Terakhir'));
    await tester.pumpAndSettle();

    expect(find.text('Detail Tagihan'), findsOneWidget);
    expect(find.text('INV/EPR-IPL/3767/VII/2026'), findsOneWidget);
    expect(find.text('Riwayat Pembayaran'), findsOneWidget);
  });
}

void statusBadgeTest() {
  Color warnaTeks(WidgetTester tester, String teks) => tester.widget<Text>(find.text(teks)).style!.color!;

  testWidgets('badge: "Belum lunas" berwarna invoice (bukan hijau), "Lunas" berwarna payment', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Column(children: [StatusBadge(status: 'Belum lunas'), StatusBadge(status: 'Lunas')]),
    ));

    expect(warnaTeks(tester, 'BELUM LUNAS'), AppColors.invoiceBadgeFg);
    expect(warnaTeks(tester, 'LUNAS'), AppColors.paymentBadgeFg);
  });
}
