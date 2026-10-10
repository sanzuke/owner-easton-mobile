import 'package:flutter_test/flutter_test.dart';
import 'package:owner_easton_mobile/features/utility/data/utility_repository.dart';

// JSON mengikuti respons nyata GET /api/v1/utility/air (docs/96b §9b).
void main() {
  test('respons air: ringkasan, tahun, dan tagihan null = belum ditagih', () {
    final air = UtilityAir.fromJson({
      'tahun': 2026,
      'tahun_tersedia': [2026, 2025],
      'meter_terakhir': 151,
      'tarif_per_m3': 6900,
      'items': [
        {'rekening': 'A0002', 'bulan': 5, 'tahun': 2026, 'meter_awal': 149, 'meter_akhir': 151, 'pakai': 2, 'tagihan': null},
        {'rekening': 'A0002', 'bulan': 3, 'tahun': 2026, 'meter_awal': 147, 'meter_akhir': 147, 'pakai': 0, 'tagihan': 0},
        {'rekening': 'A0002', 'bulan': 2, 'tahun': 2026, 'meter_awal': 145, 'meter_akhir': 147, 'pakai': 2, 'tagihan': 13800},
      ],
    });
    expect(air.tahun, 2026);
    expect(air.tahunTersedia, [2026, 2025]);
    expect(air.meterTerakhir, 151);
    expect(air.tarifPerM3, 6900);
    expect(air.items[0].tagihan, isNull); // belum masuk invoice
    expect(air.items[1].tagihan, 0); // sudah ditagih Rp0 (pakai 0) -- beda dari null
    expect(air.items[2].tagihan, 13800);
  });

  test('unit tanpa rekening air: tahun & meter null, daftar kosong', () {
    final air = UtilityAir.fromJson({
      'tahun': null,
      'tahun_tersedia': [],
      'meter_terakhir': null,
      'tarif_per_m3': 6900,
      'items': [],
    });
    expect(air.tahun, isNull);
    expect(air.meterTerakhir, isNull);
    expect(air.items, isEmpty);
  });
}
