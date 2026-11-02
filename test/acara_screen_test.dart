import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:owner_easton_mobile/core/theme/app_theme.dart';
import 'package:owner_easton_mobile/core/providers/core_providers.dart';
import 'package:owner_easton_mobile/features/acara/application/pembuka_berkas.dart';
import 'package:owner_easton_mobile/features/acara/data/berkas_acara.dart';
import 'package:owner_easton_mobile/features/acara/presentation/acara_detail_screen.dart';
import 'package:owner_easton_mobile/features/acara/presentation/acara_screen.dart';
import 'package:owner_easton_mobile/features/acara/presentation/acara_voting_screen.dart';
import 'package:owner_easton_mobile/features/acara/presentation/pratinjau_gambar_screen.dart';
import 'package:owner_easton_mobile/features/notifikasi/application/notifikasi_providers.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'support/fake_api.dart';

class _PembukaPalsu implements PembukaBerkas {
  final dibuka = <({String nama, JenisBerkas jenis, int panjang})>[];
  bool berhasil = true;

  @override
  Future<bool> buka(Uint8List bytes, {required String nama, required JenisBerkas jenis}) async {
    dibuka.add((nama: nama, jenis: jenis, panjang: bytes.length));
    return berhasil;
  }
}

Map<String, dynamic> _item(String kode, {int status = 1, String? kehadiran, bool banner = false, String? batas}) => {
      'id_acara': 1, 'kode': kode, 'nama': 'Acara $kode', 'deskripsi': 'Deskripsi $kode', 'lokasi': 'Aula Easton',
      'link_online': null, 'tgl_mulai': '2026-11-20 09:00:00', 'tgl_selesai': '2026-11-20 12:00:00',
      'batas_rsvp': batas, 'status': status, 'ada_banner': banner,
      'kehadiran': kehadiran, 'mode': kehadiran == null ? null : (kehadiran == 'online' ? 'online' : 'offline'),
    };

Map<String, dynamic> _detail(
  String kode, {
  bool banner = false,
  Map<String, bool> dok = const {'undangan': false, 'tatib': false, 'materi': false},
  Map<String, dynamic>? peserta,
  bool bisaRsvp = true,
  bool sudahCheckin = false,
  bool adaVoting = false,
}) =>
    {
      ..._item(kode, banner: banner, batas: '2026-11-18 17:00:00', kehadiran: peserta?['kehadiran'] as String?),
      'link_maps': 'https://maps.example/x', 'deskripsi_materi': 'Materi rapat',
      'dokumen': dok, 'peserta': peserta, 'bisa_rsvp': bisaRsvp, 'sudah_checkin': sudahCheckin, 'ada_voting': adaVoting,
    };

Future<AdapterPalsu> _pasang(
  WidgetTester tester,
  Map<String, RespPalsu> rute,
  Widget home, {
  _PembukaPalsu? pembuka,
  Size ukuran = const Size(412, 900),
}) async {
  await initializeDateFormatting('id_ID');
  tester.view.physicalSize = ukuran;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final (api, adapter) = apiPalsu(rute);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(api),
        notifikasiBelumDibacaProvider.overrideWith((ref) async => 0),
        if (pembuka != null) pembukaBerkasProvider.overrideWithValue(pembuka),
      ],
      child: MaterialApp(theme: AppTheme.light(), home: home),
    ),
  );
  await tester.pumpAndSettle();
  return adapter;
}

void main() {
  group('tab Acara (daftar)', () {
    testWidgets('menampilkan acara aktif dengan status RSVP; Riwayat kosong memakai pesan kosong', (tester) async {
      await _pasang(tester, {
        'GET /acara': RespPalsu.json(200, amplop({
          'aktif': [
            _item('A1', kehadiran: 'dikuasakan'),
            _item('A2', batas: '2026-11-18 17:00:00'),
          ],
          'riwayat': <Map<String, dynamic>>[],
        })),
      }, const AcaraScreen());

      expect(find.text('Acara A1'), findsOneWidget);
      expect(find.text('Kehadiran: Offline (dikuasakan)'), findsOneWidget);
      expect(find.text('Acara A2'), findsOneWidget);
      expect(find.text('Batas konfirmasi: 18 Nov 2026'), findsOneWidget);
      expect(find.text('Aula Easton'), findsNWidgets(2));

      await tester.tap(find.text('Riwayat'));
      await tester.pumpAndSettle();
      expect(find.text('Belum ada riwayat acara.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tanpa acara sama sekali: pesan kosong di tab Aktif', (tester) async {
      await _pasang(tester, {
        'GET /acara': RespPalsu.json(200, amplop({'aktif': <Object>[], 'riwayat': <Object>[]})),
      }, const AcaraScreen());
      expect(find.text('Belum ada acara aktif.'), findsOneWidget);
    });

    testWidgets('galat jaringan/server: pesan + Coba lagi memuat ulang', (tester) async {
      final rute = <String, RespPalsu>{};
      await _pasang(tester, rute, const AcaraScreen());
      // rute kosong -> adapter membalas 500; tampilan galat dengan tombol coba lagi
      expect(find.text('Coba lagi'), findsOneWidget);
      expect(find.textContaining('Tidak ada rute palsu'), findsOneWidget);

      rute['GET /acara'] = RespPalsu.json(200, amplop({'aktif': [_item('A1')], 'riwayat': <Object>[]}));
      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();
      expect(find.text('Acara A1'), findsOneWidget);
    });

    testWidgets('401: pesan sesi berakhir', (tester) async {
      await _pasang(tester, {
        'GET /acara': RespPalsu.json(401, {'status': false, 'data': null, 'message': 'Unauthenticated.', 'errors': null}),
      }, const AcaraScreen());
      expect(find.textContaining('Sesi Anda berakhir'), findsOneWidget);
    });

    testWidgets('mengetuk kartu membuka detail acara', (tester) async {
      await _pasang(tester, {
        'GET /acara': RespPalsu.json(200, amplop({'aktif': [_item('A1')], 'riwayat': <Object>[]})),
        'GET /acara/A1': RespPalsu.json(200, amplop(_detail('A1'))),
      }, const AcaraScreen());
      await tester.tap(find.text('Acara A1'));
      await tester.pumpAndSettle();
      expect(find.text('Detail Acara'), findsOneWidget);
      expect(find.text('Materi rapat'), findsOneWidget);
    });
  });

  group('detail acara', () {
    testWidgets('banner diunduh dengan bytes lalu tampil sebagai gambar', (tester) async {
      final adapter = await _pasang(tester, {
        'GET /acara/B1': RespPalsu.json(200, amplop(_detail('B1', banner: true))),
        'GET /acara/B1/banner': RespPalsu.bytes(pngKecil, contentType: 'image/png'),
      }, const AcaraDetailScreen(kode: 'B1'));
      expect(adapter.terakhir('GET /acara/B1/banner'), isNotNull);
      // skipOffstage:false — di tes gambar belum terdekode sehingga berukuran 0 dan dianggap di luar layar.
      expect(find.byType(Image, skipOffstage: false), findsOneWidget);
      expect(find.text('Acara B1'), findsOneWidget);
    });

    testWidgets('banner gagal (404): detail tetap tampil tanpa gambar', (tester) async {
      await _pasang(tester, {
        'GET /acara/B1': RespPalsu.json(200, amplop(_detail('B1', banner: true))),
        'GET /acara/B1/banner': RespPalsu.json(404, {'message': 'Not Found'}),
      }, const AcaraDetailScreen(kode: 'B1'));
      expect(find.byType(Image, skipOffstage: false), findsNothing);
      expect(find.text('Acara B1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tanpa dokumen: bagian Dokumen tidak muncul; dengan dokumen hanya yang tersedia', (tester) async {
      await _pasang(tester, {
        'GET /acara/D0': RespPalsu.json(200, amplop(_detail('D0'))),
      }, const AcaraDetailScreen(kode: 'D0'));
      expect(find.text('Dokumen'), findsNothing);
    });

    testWidgets('dokumen PDF dibuka lewat aplikasi pembaca; gambar lewat layar pratinjau', (tester) async {
      final pembuka = _PembukaPalsu();
      final adapter = await _pasang(tester, {
        'GET /acara/D1': RespPalsu.json(200, amplop(_detail('D1', dok: {'undangan': true, 'tatib': true, 'materi': false}))),
        'GET /acara/D1/dokumen/undangan': RespPalsu.bytes(pdfKecil, contentType: 'application/pdf'),
        'GET /acara/D1/dokumen/tatib': RespPalsu.bytes(pngKecil, contentType: 'image/png'),
      }, const AcaraDetailScreen(kode: 'D1'), pembuka: pembuka);

      expect(find.text('Dokumen'), findsOneWidget);
      expect(find.text('Undangan'), findsOneWidget);
      expect(find.text('Tata Tertib'), findsOneWidget);
      expect(find.text('Materi'), findsNothing);

      await tester.tap(find.text('Undangan'));
      await tester.pumpAndSettle();
      expect(adapter.terakhir('GET /acara/D1/dokumen/undangan'), isNotNull);
      expect(pembuka.dibuka.single.jenis, JenisBerkas.pdf);
      expect(pembuka.dibuka.single.nama, 'Undangan-D1');

      await tester.tap(find.text('Tata Tertib'));
      await tester.pumpAndSettle();
      expect(find.byType(PratinjauGambarScreen), findsOneWidget);
      expect(pembuka.dibuka, hasLength(1)); // gambar tidak lewat pembaca eksternal
    });

    testWidgets('dokumen 404 / tidak ada aplikasi pembaca: snackbar, tidak crash', (tester) async {
      final pembuka = _PembukaPalsu()..berhasil = false;
      await _pasang(tester, {
        'GET /acara/D2': RespPalsu.json(200, amplop(_detail('D2', dok: {'undangan': true, 'tatib': true, 'materi': false}))),
        'GET /acara/D2/dokumen/undangan': RespPalsu.bytes(pdfKecil),
        'GET /acara/D2/dokumen/tatib': RespPalsu.json(404, {'message': 'Not Found'}),
      }, const AcaraDetailScreen(kode: 'D2'), pembuka: pembuka);

      await tester.tap(find.text('Undangan'));
      await tester.pumpAndSettle();
      expect(find.text('Tidak ada aplikasi di perangkat untuk membuka berkas ini.'), findsOneWidget);

      ScaffoldMessenger.of(tester.element(find.text('Tata Tertib'))).clearSnackBars();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tata Tertib'));
      await tester.pumpAndSettle();
      expect(find.text('Tata Tertib tidak tersedia.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('RSVP online: formulir mengirim POST dan detail dimuat ulang', (tester) async {
      final rute = <String, RespPalsu>{
        'GET /acara/R1': RespPalsu.json(200, amplop(_detail('R1'))),
        'POST /acara/R1/rsvp': RespPalsu.json(200, amplop(null, 'Terima kasih, konfirmasi kehadiran Anda tersimpan.')),
      };
      final adapter = await _pasang(tester, rute, const AcaraDetailScreen(kode: 'R1'));
      expect(find.text('Belum ada konfirmasi dari unit Anda.'), findsOneWidget);

      rute['GET /acara/R1'] = RespPalsu.json(200, amplop(_detail('R1', peserta: {
        'kehadiran': 'online', 'mode': 'online', 'nama_hadir': 'Budi', 'nama_wakil': '',
        'ada_surat_kuasa': false, 'ada_ktp_wakil': false, 'ada_surat_izin_huni': false,
        'punya_qr': false, 'checkin_status': 0,
      })));
      await tester.tap(find.text('Konfirmasi Kehadiran').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Budi');
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      final post = adapter.terakhir('POST /acara/R1/rsvp');
      expect(post, isNotNull);
      expect(find.text('Status: Online'), findsOneWidget);
      expect(find.text('Ubah Konfirmasi'), findsOneWidget);
    });

    testWidgets('RSVP dikuasakan tanpa berkas ditolak di app sebelum kirim', (tester) async {
      final adapter = await _pasang(tester, {
        'GET /acara/R2': RespPalsu.json(200, amplop(_detail('R2'))),
      }, const AcaraDetailScreen(kode: 'R2'));
      await tester.tap(find.text('Konfirmasi Kehadiran').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Offline'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dikuasakan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
      expect(find.text('Nama penerima kuasa wajib diisi.'), findsOneWidget);
      expect(adapter.terakhir('POST /acara/R2/rsvp'), isNull);
    });

    testWidgets('RSVP ditolak server (403): pesan server tampil di formulir', (tester) async {
      await _pasang(tester, {
        'GET /acara/R3': RespPalsu.json(200, amplop(_detail('R3'))),
        'POST /acara/R3/rsvp': RespPalsu.json(403, {'status': false, 'data': null, 'message': 'Konfirmasi kehadiran sudah ditutup untuk acara ini.', 'errors': null}),
      }, const AcaraDetailScreen(kode: 'R3'));
      await tester.tap(find.text('Konfirmasi Kehadiran').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
      expect(find.text('Konfirmasi kehadiran sudah ditutup untuk acara ini.'), findsOneWidget);
    });

    testWidgets('hadir fisik (punya_qr): QR check-in digambar dari token; sudah check-in mengunci RSVP', (tester) async {
      await _pasang(tester, {
        'GET /acara/Q1': RespPalsu.json(200, amplop(_detail('Q1', bisaRsvp: false, sudahCheckin: true, peserta: {
          'kehadiran': 'pemilik', 'mode': 'offline', 'nama_hadir': 'Budi', 'nama_wakil': '',
          'ada_surat_kuasa': false, 'ada_ktp_wakil': false, 'ada_surat_izin_huni': false,
          'punya_qr': true, 'checkin_status': 1,
        }))),
        'GET /acara/Q1/qr': RespPalsu.json(200, amplop({'qr_token': 'abc123', 'kode_acara': 'Q1', 'kode_unit': 'B0648', 'checkin_status': 1})),
      }, const AcaraDetailScreen(kode: 'Q1'));
      expect(find.byType(QrImageView), findsOneWidget); // token dibaca dari GET /qr (diuji di acara_test)
      expect(find.text('Unit B0648'), findsOneWidget);
      expect(find.text('Sudah check-in'), findsOneWidget);
      expect(find.textContaining('perubahan hanya oleh pengurus'), findsOneWidget);
      expect(find.text('Ubah Konfirmasi'), findsNothing);
    });

    testWidgets('RSVP sudah ditutup: tanpa tombol, ada keterangan', (tester) async {
      await _pasang(tester, {
        'GET /acara/T1': RespPalsu.json(200, amplop(_detail('T1', bisaRsvp: false))),
      }, const AcaraDetailScreen(kode: 'T1'));
      expect(find.text('Konfirmasi kehadiran sudah ditutup.'), findsOneWidget);
    });

    testWidgets('detail 404: pesan galat dari server + Coba lagi', (tester) async {
      await _pasang(tester, {
        'GET /acara/NONE': RespPalsu.json(404, {'status': false, 'data': null, 'message': 'Acara tidak ditemukan.', 'errors': null}),
      }, const AcaraDetailScreen(kode: 'NONE'));
      expect(find.text('Acara tidak ditemukan.'), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);
    });
  });

  group('voting', () {
    Map<String, dynamic> voting({bool sudah = false, bool buka = true, bool tampilHasil = true, String tipe = 'single'}) => {
          'id_voting': 9, 'pertanyaan': 'Setujui anggaran?', 'tipe': tipe,
          'waktu_buka': null, 'waktu_habis': null, 'tampil_hasil': tampilHasil, 'buka': buka,
          'label_tutup': buka ? null : 'Ditutup', 'alasan_tutup': buka ? null : 'Voting ini sudah ditutup oleh pengurus.',
          'sudah': sudah, 'pilihan': sudah ? [21] : <int>[],
          'opsi': [
            {'id_opsi': 21, 'teks_opsi': 'Ya', 'gambar': null, 'urutan': 1},
            {'id_opsi': 22, 'teks_opsi': 'Tidak', 'gambar': null, 'urutan': 2},
          ],
        };

    testWidgets('pilih opsi, kirim suara, lalu daftar dimuat ulang dan hasil tampil sebagai batang persentase', (tester) async {
      final rute = <String, RespPalsu>{
        'GET /acara/V1/voting': RespPalsu.json(200, amplop({'sudah_rsvp': true, 'votings': [voting()]})),
        'POST /acara/voting/9/suara': RespPalsu.json(200, amplop(null, 'Terima kasih, suara Anda tersimpan.')),
        'GET /acara/voting/9/hasil': RespPalsu.json(200, amplop({'pemilih': 4, 'opsi': [{'teks_opsi': 'Ya', 'jml': 3}, {'teks_opsi': 'Tidak', 'jml': 1}]})),
      };
      final adapter = await _pasang(tester, rute, const AcaraVotingScreen(kode: 'V1'));
      expect(find.text('Setujui anggaran?'), findsOneWidget);
      final kirim = find.widgetWithText(FilledButton, 'Kirim Suara');
      expect(tester.widget<FilledButton>(kirim).onPressed, isNull); // belum memilih

      await tester.tap(find.text('Ya'));
      await tester.pump();
      expect(tester.widget<FilledButton>(kirim).onPressed, isNotNull);

      rute['GET /acara/V1/voting'] = RespPalsu.json(200, amplop({'sudah_rsvp': true, 'votings': [voting(sudah: true)]}));
      await tester.tap(kirim);
      await tester.pumpAndSettle();
      expect(adapter.terakhir('POST /acara/voting/9/suara')!.data, {'opsi': [21]});
      expect(find.text('Suara Anda sudah tersimpan.'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Kirim Suara'), findsNothing);

      await tester.tap(find.text('Lihat Hasil'));
      await tester.pumpAndSettle();
      expect(find.text('Pemilih: 4 unit'), findsOneWidget);
      expect(find.text('3 (75%)'), findsOneWidget);
      expect(find.text('1 (25%)'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNWidgets(2));
      await tester.tap(find.text('Sembunyikan Hasil'));
      await tester.pumpAndSettle();
      expect(find.text('Pemilih: 4 unit'), findsNothing);
    });

    testWidgets('multi-pilihan: kotak centang, kirim banyak opsi', (tester) async {
      final adapter = await _pasang(tester, {
        'GET /acara/V2/voting': RespPalsu.json(200, amplop({'sudah_rsvp': true, 'votings': [voting(tipe: 'multi', tampilHasil: false)]})),
        'POST /acara/voting/9/suara': RespPalsu.json(200, amplop(null, 'ok')),
      }, const AcaraVotingScreen(kode: 'V2'));
      expect(find.text('Boleh memilih lebih dari satu.'), findsOneWidget);
      expect(find.text('Lihat Hasil'), findsNothing);
      await tester.tap(find.text('Ya'));
      await tester.tap(find.text('Tidak'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Kirim Suara'));
      await tester.pumpAndSettle();
      expect(adapter.terakhir('POST /acara/voting/9/suara')!.data['opsi'], unorderedEquals([21, 22]));
    });

    testWidgets('voting tutup: alasan tampil, opsi tidak bisa dipilih, tanpa tombol kirim', (tester) async {
      await _pasang(tester, {
        'GET /acara/V3/voting': RespPalsu.json(200, amplop({'sudah_rsvp': true, 'votings': [voting(buka: false)]})),
      }, const AcaraVotingScreen(kode: 'V3'));
      expect(find.textContaining('Voting ini sudah ditutup oleh pengurus.'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Kirim Suara'), findsNothing);
    });

    testWidgets('server menolak suara (409 sudah memberi suara): pesan tampil, tidak crash', (tester) async {
      await _pasang(tester, {
        'GET /acara/V4/voting': RespPalsu.json(200, amplop({'sudah_rsvp': true, 'votings': [voting()]})),
        'POST /acara/voting/9/suara': RespPalsu.json(409, {'status': false, 'data': null, 'message': 'Anda sudah memberikan suara pada voting ini.', 'errors': null}),
      }, const AcaraVotingScreen(kode: 'V4'));
      await tester.tap(find.text('Ya'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Kirim Suara'));
      await tester.pumpAndSettle();
      expect(find.text('Anda sudah memberikan suara pada voting ini.'), findsOneWidget);
    });

    testWidgets('belum RSVP / belum ada voting / galat: tiap keadaan punya pesan', (tester) async {
      await _pasang(tester, {
        'GET /acara/V5/voting': RespPalsu.json(200, amplop({'sudah_rsvp': false, 'votings': <Object>[]})),
      }, const AcaraVotingScreen(kode: 'V5'));
      expect(find.textContaining('Konfirmasi kehadiran terlebih dahulu'), findsOneWidget);

      await _pasang(tester, {
        'GET /acara/V6/voting': RespPalsu.json(200, amplop({'sudah_rsvp': true, 'votings': <Object>[]})),
      }, const AcaraVotingScreen(kode: 'V6'));
      expect(find.text('Belum ada voting.'), findsOneWidget);

      await _pasang(tester, {
        'GET /acara/V7/voting': RespPalsu.json(404, {'status': false, 'data': null, 'message': 'Acara tidak ditemukan.', 'errors': null}),
      }, const AcaraVotingScreen(kode: 'V7'));
      expect(find.text('Acara tidak ditemukan.'), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);
    });
  });

  // Audit Row-tombol: FilledButton/ElevatedButton di tema app berminimumSize lebar tak hingga.
  group('Row tombol pada layar sempit (tanpa overflow / infinite width)', () {
    for (final lebar in [220.0, 280.0]) {
      testWidgets('kartu voting: Kirim Suara + Lihat Hasil pada lebar ${lebar.toInt()}', (tester) async {
        await _pasang(
          tester,
          {
            'GET /acara/N1/voting': RespPalsu.json(200, amplop({
              'sudah_rsvp': true,
              'votings': [
                {
                  'id_voting': 9, 'pertanyaan': 'Setujui anggaran tahunan pengelolaan lingkungan Easton Park?', 'tipe': 'single',
                  'tampil_hasil': true, 'buka': true, 'sudah': false, 'pilihan': <int>[],
                  'opsi': [
                    {'id_opsi': 21, 'teks_opsi': 'Ya, setuju sepenuhnya dengan seluruh rincian anggaran', 'urutan': 1},
                  ],
                },
              ],
            })),
            'GET /acara/voting/9/hasil': RespPalsu.json(200, amplop({'pemilih': 1, 'opsi': [{'teks_opsi': 'Ya, setuju sepenuhnya dengan seluruh rincian anggaran', 'jml': 1}]})),
          },
          const AcaraVotingScreen(kode: 'N1'),
          ukuran: Size(lebar, 800),
        );
        expect(find.text('Kirim Suara'), findsOneWidget);
        expect(find.text('Lihat Hasil'), findsOneWidget);
        await tester.tap(find.text('Lihat Hasil'));
        await tester.pumpAndSettle();
        expect(find.textContaining('Pemilih: 1 unit'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
