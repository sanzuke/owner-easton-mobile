import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:owner_easton_mobile/features/tagihan/application/tagihan_providers.dart';
import 'package:owner_easton_mobile/features/tagihan/data/tagihan_repository.dart';
import 'package:owner_easton_mobile/features/tagihan/presentation/tagihan_detail_screen.dart';

Map<String, dynamic> _json({List<Map<String, dynamic>>? pembayaran}) => {
      'invoice': 'INV/EPR-IPL/3767/VII/2026',
      'tanggal_terbit': '2026-07-01',
      'unit': 'B0648',
      'items': [
        {'nama_tag': 'IPL', 'jumlah': 1219500.0, 'status': 1, 'tanggal': '2026-07-01'},
        {'nama_tag': 'IPL', 'jumlah': 1219500.0, 'status': 2, 'tanggal': '2026-07-05'},
      ],
      'pembayaran': ?pembayaran,
    };

const _kwitansi = {
  'jenis': 'payment', 'id': 8801, 'nomor': '1893/Kwt-INV/V/2026', 'tanggal': '2026-04-25',
  'metode': 'BANK BJB', 'jumlah': 1219500.0, 'cetak_url': 'https://bms2.example/share/ipl?t=abc',
};
const _cn = {
  'jenis': 'cn', 'id': 7, 'nomor': 'CN/1', 'tanggal': '2026-05-01', 'metode': null, 'jumlah': 50000.0, 'cetak_url': null,
};

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  test('TagihanDetail membaca pembayaran; server lama tanpa field pembayaran tetap terbaca', () {
    final d = TagihanDetail.fromJson(_json(pembayaran: [_kwitansi, _cn]), '1');
    expect(d.pembayaran, hasLength(2));
    expect(d.pembayaran[0].creditNote, isFalse);
    expect(d.pembayaran[0].tanggal, DateTime(2026, 4, 25));
    expect(d.pembayaran[0].cetakUrl, contains('share/ipl'));
    expect(d.pembayaran[1].creditNote, isTrue);
    expect(d.pembayaran[1].cetakUrl, isNull);
    expect(d.pembayaran[1].metode, isNull);

    expect(TagihanDetail.fromJson(_json(), '1').pembayaran, isEmpty);
  });

  Future<void> pasang(WidgetTester tester, TagihanDetail d) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [tagihanDetailProvider('1').overrideWith((ref) async => d)],
      child: const MaterialApp(home: TagihanDetailScreen(id: '1')),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('Riwayat Pembayaran: tombol Print hanya untuk kwitansi, credit note tanpa tombol', (tester) async {
    await pasang(tester, TagihanDetail.fromJson(_json(pembayaran: [_kwitansi, _cn]), '1'));

    expect(find.text('Riwayat Pembayaran'), findsOneWidget);
    expect(find.text('1893/Kwt-INV/V/2026'), findsOneWidget);
    expect(find.text('CN/1'), findsOneWidget);
    expect(find.text('Print'), findsOneWidget);
  });

  testWidgets('invoice belum dibayar: bagian Riwayat Pembayaran tidak muncul', (tester) async {
    await pasang(tester, TagihanDetail.fromJson(_json(pembayaran: []), '1'));

    expect(find.text('Riwayat Pembayaran'), findsNothing);
    expect(find.text('Print'), findsNothing);
  });
}
