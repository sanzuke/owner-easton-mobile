import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:owner_easton_mobile/core/network/api_envelope.dart';
import 'package:owner_easton_mobile/features/acara/data/acara_repository.dart';
import 'package:owner_easton_mobile/features/acara/data/berkas_acara.dart';

import 'support/fake_api.dart';

void main() {
  test('GET /acara: aktif & riwayat, batas_rsvp kosong/0000 jadi null (docs/96b §11c)', () {
    final d = DaftarAcara.fromJson({
      'aktif': [
        {
          'id_acara': 3, 'kode': 'RUPS-2026', 'nama': 'RUPS', 'deskripsi': null, 'lokasi': 'Aula',
          'link_online': '', 'tgl_mulai': '2026-11-01 09:00:00', 'tgl_selesai': null,
          'batas_rsvp': '0000-00-00 00:00:00', 'status': 1, 'ada_banner': false,
          'kehadiran': 'dikuasakan', 'mode': 'offline',
        },
        {
          'id_acara': 4, 'kode': 'B', 'nama': 'B', 'tgl_mulai': '2026-12-01 09:00:00',
          'batas_rsvp': '2026-11-25 17:00:00', 'status': 1, 'kehadiran': null, 'mode': null,
        },
      ],
      'riwayat': [],
    });
    expect(d.aktif.length, 2);
    final a = d.aktif.first;
    expect(a.batasRsvp, isNull);
    expect(a.linkOnline, isNull);
    expect(a.deskripsi, '');
    expect(a.sudahRsvp, isTrue);
    expect(a.tglMulai, DateTime(2026, 11, 1, 9));
    expect(d.aktif[1].sudahRsvp, isFalse);
    expect(d.aktif[1].batasRsvp, DateTime(2026, 11, 25, 17));
  });

  test('GET /acara/{kode}: peserta, dokumen, flag RSVP & check-in', () {
    final d = DetailAcara.fromJson({
      'kode': 'RUPS-2026', 'nama': 'RUPS', 'status': 1,
      'link_maps': 'https://maps.example/x', 'deskripsi_materi': 'Materi',
      'dokumen': {'undangan': true, 'tatib': false, 'materi': true},
      'peserta': {
        'kehadiran': 'dikuasakan', 'mode': 'offline', 'nama_hadir': 'Budi', 'nama_wakil': 'Siti',
        'ada_surat_kuasa': true, 'ada_ktp_wakil': true, 'ada_surat_izin_huni': false,
        'punya_qr': true, 'checkin_status': 0,
      },
      'bisa_rsvp': true, 'sudah_checkin': false, 'ada_voting': true,
    });
    expect(d.acara.kehadiran, 'dikuasakan');
    expect(d.adaUndangan, isTrue);
    expect(d.adaTatib, isFalse);
    expect(d.peserta!.punyaQr, isTrue);
    expect(d.peserta!.adaSuratIzinHuni, isFalse);
    expect(d.peserta!.sudahCheckin, isFalse);
    expect(d.bisaRsvp, isTrue);
    expect(d.adaVoting, isTrue);
  });

  test('detail tanpa peserta: belum RSVP', () {
    final d = DetailAcara.fromJson({'kode': 'X', 'nama': 'X', 'status': 1, 'peserta': null, 'bisa_rsvp': true});
    expect(d.peserta, isNull);
    expect(d.acara.sudahRsvp, isFalse);
  });

  test('GET /acara/{kode}/voting dan hasil', () {
    final v = DaftarVoting.fromJson({
      'sudah_rsvp': true,
      'votings': [
        {
          'id_voting': 9, 'pertanyaan': 'Setuju?', 'tipe': 'single', 'buka': false,
          'label_tutup': 'Ditutup', 'alasan_tutup': 'Voting ini sudah ditutup.',
          'tampil_hasil': true, 'sudah': true, 'pilihan': [21],
          'opsi': [
            {'id_opsi': 21, 'teks_opsi': 'Ya'},
            {'id_opsi': 22, 'teks_opsi': 'Tidak'},
          ],
        },
        {'id_voting': 10, 'pertanyaan': 'Pilih', 'tipe': 'multi', 'buka': true, 'opsi': []},
      ],
    });
    expect(v.sudahRsvp, isTrue);
    expect(v.votings[0].multi, isFalse);
    expect(v.votings[0].pilihan, [21]);
    expect(v.votings[0].opsi.map((o) => o.teks), ['Ya', 'Tidak']);
    expect(v.votings[1].multi, isTrue);
    expect(v.votings[1].buka, isTrue);

    final h = HasilVoting.fromJson({
      'pemilih': 12,
      'opsi': [
        {'teks_opsi': 'Ya', 'jml': 9},
        {'teks_opsi': 'Tidak', 'jml': '3'},
      ],
    });
    expect(h.pemilih, 12);
    expect(h.opsi[1].jml, 3);
  });

  test('GET /acara/{kode}/qr', () {
    final q = QrKehadiran.fromJson({'qr_token': 'abc', 'kode_acara': 'X', 'kode_unit': 'A0101', 'checkin_status': 1});
    expect(q.token, 'abc');
    expect(q.sudahCheckin, isTrue);
  });

  test('ada_banner dibaca dari item daftar dan tetap ada di detail', () {
    final d = DaftarAcara.fromJson({
      'aktif': [
        {'kode': 'A', 'nama': 'A', 'ada_banner': true, 'status': 1},
        {'kode': 'B', 'nama': 'B', 'ada_banner': false, 'status': 1},
      ],
    });
    expect(d.aktif[0].adaBanner, isTrue);
    expect(d.aktif[1].adaBanner, isFalse);
    expect(d.riwayat, isEmpty);
    final det = DetailAcara.fromJson({'kode': 'A', 'nama': 'A', 'status': 1, 'ada_banner': true, 'peserta': {'kehadiran': 'online', 'mode': 'online'}});
    expect(det.acara.adaBanner, isTrue);
    expect(det.acara.kehadiran, 'online');
  });

  test('HasilVoting.bagian: persentase terhadap pemilih, aman bila pemilih 0', () {
    const h = HasilVoting(pemilih: 4, opsi: [(teks: 'Ya', jml: 3), (teks: 'Tidak', jml: 1)]);
    expect(h.bagian(3), 0.75);
    expect(h.bagian(9), 1.0); // multi-pilihan tidak boleh melebihi 100%
    expect(const HasilVoting().bagian(2), 0);
  });

  test('deteksiBerkas mengenali PDF, JPG, PNG, DOCX, DOC dari byte awal', () {
    expect(deteksiBerkas(pdfKecil), JenisBerkas.pdf);
    expect(deteksiBerkas(pngKecil), JenisBerkas.png);
    expect(deteksiBerkas(Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0])), JenisBerkas.jpg);
    expect(deteksiBerkas(Uint8List.fromList([0x50, 0x4B, 0x03, 0x04, 0])), JenisBerkas.docx);
    expect(deteksiBerkas(Uint8List.fromList([0xD0, 0xCF, 0x11, 0xE0, 0])), JenisBerkas.doc);
    expect(deteksiBerkas(Uint8List.fromList([1, 2, 3])), JenisBerkas.tidakDikenal);
    expect(deteksiBerkas(Uint8List(0)), JenisBerkas.tidakDikenal);
    expect(JenisBerkas.png.gambar, isTrue);
    expect(JenisBerkas.pdf.gambar, isFalse);
  });

  group('AcaraRepository lewat HTTP palsu', () {
    test('getList dan getDetail memakai envelope {status,data}', () async {
      final (api, adapter) = apiPalsu({
        'GET /acara': RespPalsu.json(200, amplop({
          'aktif': [
            {'kode': 'RUPS-2026', 'nama': 'RUPS', 'status': 1, 'ada_banner': true, 'kehadiran': 'online', 'mode': 'online'},
          ],
          'riwayat': [
            {'kode': 'LAMA', 'nama': 'Lama', 'status': 2, 'kehadiran': null, 'mode': null},
          ],
        })),
        'GET /acara/RUPS-2026': RespPalsu.json(200, amplop({
          'kode': 'RUPS-2026', 'nama': 'RUPS', 'status': 1,
          'dokumen': {'undangan': true, 'tatib': true, 'materi': false},
          'peserta': null, 'bisa_rsvp': true, 'sudah_checkin': false, 'ada_voting': false,
        })),
      });
      final repo = AcaraRepository(apiClient: api);
      final list = await repo.getList();
      expect(list.aktif.single.kode, 'RUPS-2026');
      expect(list.aktif.single.adaBanner, isTrue);
      expect(list.riwayat.single.status, 2);
      final det = await repo.getDetail('RUPS-2026');
      expect(det.adaUndangan, isTrue);
      expect(det.adaMateri, isFalse);
      expect(det.peserta, isNull);
      expect(adapter.permintaan.map((r) => r.path), ['/acara', '/acara/RUPS-2026']);
    });

    test('getBanner dan getDokumen mengunduh bytes dari path yang benar', () async {
      final (api, adapter) = apiPalsu({
        'GET /acara/X/banner': RespPalsu.bytes(pngKecil, contentType: 'image/png'),
        'GET /acara/X/dokumen/tatib': RespPalsu.bytes(pdfKecil, contentType: 'application/pdf'),
      });
      final repo = AcaraRepository(apiClient: api);
      expect(deteksiBerkas(await repo.getBanner('X')), JenisBerkas.png);
      final dok = await repo.getDokumen('X', JenisDokumenAcara.tatib);
      expect(deteksiBerkas(dok), JenisBerkas.pdf);
      expect(adapter.terakhir('GET /acara/X/dokumen/tatib'), isNotNull);
    });

    test('dokumen 404 (JSON bawaan Laravel) dan 401 menjadi ApiException dengan pesan dari body', () async {
      final (api, _) = apiPalsu({
        'GET /acara/X/dokumen/materi': RespPalsu.json(404, {'message': 'Not Found'}),
        'GET /acara/X/banner': RespPalsu.json(401, {'status': false, 'data': null, 'message': 'Unauthenticated.', 'errors': null}),
      });
      final repo = AcaraRepository(apiClient: api);
      await expectLater(
        repo.getDokumen('X', JenisDokumenAcara.materi),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 404).having((e) => e.message, 'message', 'Not Found')),
      );
      await expectLater(
        repo.getBanner('X'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 401).having((e) => e.message, 'message', 'Unauthenticated.')),
      );
    });

    test('rsvp online: multipart berisi cara+nama_hadir tanpa offline_tipe; pesan dari server dikembalikan', () async {
      final (api, adapter) = apiPalsu({
        'POST /acara/X/rsvp': RespPalsu.json(200, amplop(null, 'Terima kasih, konfirmasi kehadiran Anda tersimpan.')),
      });
      final pesan = await AcaraRepository(apiClient: api).rsvp('X', cara: 'online', namaHadir: 'Budi');
      expect(pesan, startsWith('Terima kasih'));
      final form = adapter.terakhir('POST /acara/X/rsvp')!.data as FormData;
      final f = {for (final e in form.fields) e.key: e.value};
      expect(f['cara'], 'online');
      expect(f['nama_hadir'], 'Budi');
      expect(f.containsKey('offline_tipe'), isFalse);
      expect(f.containsKey('nama_wakil_kuasa'), isFalse);
      expect(form.files, isEmpty);
    });

    test('rsvp ditolak backend (403 batas RSVP): ApiException membawa pesan', () async {
      final (api, _) = apiPalsu({
        'POST /acara/X/rsvp': RespPalsu.json(403, {'status': false, 'data': null, 'message': 'Konfirmasi kehadiran sudah ditutup untuk acara ini.', 'errors': null}),
      });
      await expectLater(
        AcaraRepository(apiClient: api).rsvp('X', cara: 'online'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 403)),
      );
    });

    test('kirimSuara mengirim {opsi:[...]}; getHasil dan getQr terparse', () async {
      final (api, adapter) = apiPalsu({
        'POST /acara/voting/9/suara': RespPalsu.json(200, amplop(null, 'Terima kasih, suara Anda tersimpan.')),
        'GET /acara/voting/9/hasil': RespPalsu.json(200, amplop({'pemilih': 2, 'opsi': [{'teks_opsi': 'Ya', 'jml': 2}]})),
        'GET /acara/X/qr': RespPalsu.json(200, amplop({'qr_token': 'tok', 'kode_acara': 'X', 'kode_unit': 'B0648', 'checkin_status': 0})),
      });
      final repo = AcaraRepository(apiClient: api);
      expect(await repo.kirimSuara(9, [21, 22]), startsWith('Terima kasih'));
      expect(adapter.terakhir('POST /acara/voting/9/suara')!.data, {'opsi': [21, 22]});
      expect((await repo.getHasil(9)).opsi.single.jml, 2);
      final qr = await repo.getQr('X');
      expect(qr.token, 'tok');
      expect(qr.kodeUnit, 'B0648');
    });
  });
}
