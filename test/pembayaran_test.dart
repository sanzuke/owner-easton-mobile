import 'package:flutter_test/flutter_test.dart';
import 'package:owner_easton_mobile/features/pembayaran/data/pembayaran_repository.dart';

void main() {
  test('RiwayatBayar membaca kontrak GET /pembayaran (docs/96b §7)', () {
    final r = RiwayatBayar.fromJson({
      'id_bayar': 8801,
      'kwitansi': 'KWT/2026/08/0123',
      'tanggal': '2026-08-05',
      'jumlah': 1500000.0,
      'metode': 'Transfer BJB',
      'keterangan': '',
    });
    expect(r.id, '8801');
    expect(r.jumlah, 1500000);
    expect(r.tanggal, DateTime(2026, 8, 5));
    expect(r.kwitansi, 'KWT/2026/08/0123');
  });

  test('metode null (via tak ada di db_via) tidak membuat parsing gagal', () {
    final r = RiwayatBayar.fromJson({'id_bayar': 1, 'tanggal': null, 'jumlah': '250000.00', 'metode': null, 'keterangan': null});
    expect(r.metode, '-');
    expect(r.tanggal, isNull);
    expect(r.jumlah, 250000);
    expect(r.keterangan, '');
  });
}
