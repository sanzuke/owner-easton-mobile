import 'package:flutter_test/flutter_test.dart';
import 'package:owner_easton_mobile/features/acara/data/acara_repository.dart';

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
}
