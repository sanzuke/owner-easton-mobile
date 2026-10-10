import 'package:flutter_test/flutter_test.dart';
import 'package:owner_easton_mobile/features/tiket/data/tiket_repository.dart';

// Bentuk JSON mengikuti API nyata (laravel Api/V1/TiketController, docs/96b §9).
void main() {
  test('tipe dari API: id dan nama (Defect termasuk)', () {
    final tipe = TiketTipe.fromJson({'id': 1, 'nama': 'Defect', 'link': 'defect'});
    expect(tipe.id, '1');
    expect(tipe.nama, 'Defect');
  });

  test('baris daftar: id_tiket, no_form, keterangan, tipe (nama), status (label)', () {
    final t = Tiket.fromJson({
      'id_tiket': 501,
      'no_form': 'APP-501',
      'tipe': 'Defect',
      'keterangan': 'AC bocor',
      'tanggal': '2026-08-15',
      'status': 'Diproses',
    });
    expect(t.id, '501');
    expect(t.noForm, 'APP-501');
    expect(t.keterangan, 'AC bocor');
    expect(t.tipe, 'Defect');
    expect(t.status, 'Diproses');
    expect(t.tanggal, DateTime(2026, 8, 15));
  });

  test('detail: timeline dan berkas berupa objek', () {
    final d = TiketDetail.fromJson({
      'id_tiket': 501,
      'no_form': 'APP-501',
      'keterangan': 'AC bocor',
      'tanggal': '2026-08-15',
      'status': 'Diproses',
      'timeline': [
        {'tanggal': '2026-08-15 09:00:00', 'keterangan': 'Tiket dibuat'},
      ],
      'berkas': [
        {'id': 12, 'nama': 'Foto AC', 'file': '1755_ac.jpg'},
      ],
    });
    expect(d.timeline.single.keterangan, 'Tiket dibuat');
    expect(d.timeline.single.tanggal, DateTime(2026, 8, 15, 9));
    expect(d.berkas.single.nama, 'Foto AC');
  });
}
