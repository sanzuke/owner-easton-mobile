import 'package:flutter_test/flutter_test.dart';
import 'package:owner_easton_mobile/features/pbb/data/pbb_repository.dart';

// JSON mengikuti GET /api/v1/pbb (docs/96b §9c).
void main() {
  test('rincian PBB: NOP, lunas, ketersediaan SPPT dan bukti', () {
    final d = PbbData.fromJson({
      'tersedia': true,
      'nop': '32.05.123',
      'items': [
        {'id_detail': 11, 'tahun': 2026, 'tagihan': 1250000, 'lunas': false, 'ada_pdf': true, 'tgl_upload_pdf': '2026-02-10', 'ada_bukti': false, 'tgl_upload_bukti': null},
        {'id_detail': 10, 'tahun': 2025, 'tagihan': 0, 'lunas': true, 'ada_pdf': false, 'tgl_upload_pdf': null, 'ada_bukti': true, 'tgl_upload_bukti': '2026-03-01 10:00:00'},
      ],
    });
    expect(d.tersedia, isTrue);
    expect(d.nop, '32.05.123');
    expect(d.items[0].tagihan, 1250000);
    expect(d.items[0].lunas, isFalse);
    expect(d.items[0].adaPdf, isTrue);
    expect(d.items[0].tglUploadPdf, DateTime(2026, 2, 10));
    expect(d.items[1].lunas, isTrue);
    expect(d.items[1].adaBukti, isTrue);
    expect(d.items[1].tglUploadBukti, DateTime(2026, 3, 1, 10));
  });

  test('unit tanpa data PBB', () {
    final d = PbbData.fromJson({'tersedia': false, 'nop': null, 'items': []});
    expect(d.tersedia, isFalse);
    expect(d.items, isEmpty);
  });
}
