import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:owner_easton_mobile/core/theme/app_theme.dart';
import 'package:owner_easton_mobile/features/pembayaran/application/pembayaran_providers.dart';
import 'package:owner_easton_mobile/features/pembayaran/data/pembayaran_repository.dart';
import 'package:owner_easton_mobile/core/pagination/daftar_berhalaman.dart';
import 'package:owner_easton_mobile/features/tagihan/application/tagihan_providers.dart';
import 'package:owner_easton_mobile/features/tagihan/data/tagihan_repository.dart';
import 'package:owner_easton_mobile/features/tagihan/presentation/tagihan_detail_screen.dart';
import 'package:owner_easton_mobile/features/va/application/va_providers.dart';
import 'package:owner_easton_mobile/features/va/data/va_repository.dart';
import 'package:owner_easton_mobile/features/va/presentation/va_screen.dart';

Map<String, dynamic> _va({
  String status = 'belum_dibayar',
  bool dapatDibayar = true,
  String? dibayarPada,
  num? jumlahDibayar,
}) => {
  'id_billing': 42034,
  'invoice': 'INV/EPR-IPL/5445/X/2026',
  'bank': 'Bank BJB',
  'nomor_va': '1977012122121953',
  'nama_akun': 'Pemilik Unit B1953',
  'nominal': 1212600.0,
  'kedaluwarsa': '2026-12-27 00:00:00',
  'status': status,
  'dapat_dibayar': dapatDibayar,
  'dibayar_pada': dibayarPada,
  'jumlah_dibayar': jumlahDibayar,
};

Map<String, dynamic> _respons({
  Map<String, dynamic>? va,
  String? alasan,
  String pesan = '',
  Map<String, dynamic>? vaAktifDi,
}) => {
  'invoice': {'id_billing': 42034, 'nomor': 'INV/EPR-IPL/5445/X/2026'},
  'tersedia': va != null,
  'alasan': alasan,
  'pesan': pesan,
  'va_aktif_di': vaAktifDi,
  'va': va,
  'petunjuk': {
    'langkah': ['Buka mobile banking.', 'Masukkan nomor VA.'],
    'peringatan': ['Jangan lewat BI-FAST dan SKN.'],
  },
};

class _RepoPalsuPembayaran implements PembayaranRepository {
  @override
  Future<Halaman<RiwayatBayar>> getHalaman(int halaman, Periode? periode) async => const Halaman([], 1);
}

class _RepoVaPalsu implements VaRepository {
  _RepoVaPalsu(this.urutan);
  final List<Map<String, dynamic>> urutan;
  int panggilan = 0;

  @override
  Future<VaTagihan> getVaTagihan(String idBilling) async {
    final json = urutan[panggilan < urutan.length ? panggilan : urutan.length - 1];
    panggilan++;
    return VaTagihan.fromJson(json);
  }
}

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  test('VaTagihan membaca VA, petunjuk, dan status; status tak dikenal jatuh ke belum dibayar', () {
    final t = VaTagihan.fromJson(_respons(va: _va()));
    expect(t.tersedia, isTrue);
    expect(t.va!.nomorVa, '1977012122121953');
    expect(t.va!.nominal, 1212600);
    expect(t.va!.kedaluwarsa, DateTime(2026, 12, 27));
    expect(t.va!.status, VaStatus.belumDibayar);
    expect(t.va!.dapatDibayar, isTrue);
    expect(t.langkah, hasLength(2));
    expect(t.peringatan, hasLength(1));
    expect(t.nomorInvoice, 'INV/EPR-IPL/5445/X/2026');
    expect(t.invoiceAktif, isNull);

    expect(VaStatus.dari('kedaluwarsa'), VaStatus.kedaluwarsa);
    expect(VaStatus.dari('diproses'), VaStatus.diproses);
    expect(VaStatus.dari('invoice_lunas'), VaStatus.invoiceLunas);
    expect(VaStatus.dari('dibayar'), VaStatus.dibayar);
    expect(VaStatus.dari('aneh'), VaStatus.belumDibayar);
  });

  test('VaTagihan tanpa VA: tersedia false, alasan dan pesan terbaca', () {
    final t = VaTagihan.fromJson(_respons(alasan: 'belum_diterbitkan', pesan: 'Belum diterbitkan.'));
    expect(t.tersedia, isFalse);
    expect(t.alasan, 'belum_diterbitkan');
    expect(t.pesan, 'Belum diterbitkan.');
  });

  Future<_RepoVaPalsu> pasangVa(WidgetTester tester, List<Map<String, dynamic>> urutan) async {
    final repo = _RepoVaPalsu(urutan);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vaRepositoryProvider.overrideWithValue(repo),
          pembayaranRepositoryProvider.overrideWithValue(_RepoPalsuPembayaran()),
        ],
        // Tema asli: FilledButton punya minimumSize lebar tak hingga; tombol di Row tanpa Expanded/minimumSize merusak layout.
        child: MaterialApp(theme: AppTheme.light(), home: const VaScreen(idBilling: '42034')),
      ),
    );
    await tester.pumpAndSettle();
    return repo;
  }

  testWidgets('VA aktif: nomor, nominal, kedaluwarsa, langkah dan peringatan tampil; Salin menyalin nomor dan nominal', (tester) async {
    String? disalin;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') disalin = (call.arguments as Map)['text'] as String?;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));

    await pasangVa(tester, [_respons(va: _va())]);

    expect(find.text('1977012122121953'), findsOneWidget);
    expect(find.text('Rp1.212.600'), findsOneWidget);
    expect(find.text('27 Des 2026, 00:00'), findsOneWidget);
    expect(find.text('BELUM DIBAYAR'), findsOneWidget);
    expect(find.text('Buka mobile banking.'), findsOneWidget);
    expect(find.text('Jangan lewat BI-FAST dan SKN.'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Salin').first);
    await tester.pump();
    expect(disalin, '1977012122121953');
    expect(find.text('Nomor VA disalin.'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.tap(find.text('Salin').last);
    await tester.pump();
    expect(disalin, '1212600');
  });

  testWidgets('VA kedaluwarsa: badge, catatan, dan langkah bayar disembunyikan', (tester) async {
    await pasangVa(tester, [_respons(va: _va(status: 'kedaluwarsa', dapatDibayar: false))]);

    expect(find.text('KEDALUWARSA'), findsOneWidget);
    expect(find.textContaining('sudah kedaluwarsa'), findsOneWidget);
    expect(find.text('Cara bayar'), findsNothing);
    expect(find.text('Buka mobile banking.'), findsNothing);
  });

  testWidgets('VA sudah dibayar: tampil waktu + jumlah bayar dan pesan kwitansi', (tester) async {
    await pasangVa(tester, [
      _respons(va: _va(status: 'dibayar', dapatDibayar: false, dibayarPada: '2026-10-20 14:05:00', jumlahDibayar: 1212600)),
    ]);

    expect(find.text('SUDAH DIBAYAR'), findsOneWidget);
    expect(find.text('20 Okt 2026, 14:05 • Rp1.212.600'), findsOneWidget);
    expect(find.textContaining('Kwitansi ada di Riwayat Pembayaran'), findsOneWidget);
    expect(find.text('Cara bayar'), findsNothing);
  });

  testWidgets('VA belum diterbitkan: hanya pesan dari server, tanpa nomor VA atau langkah', (tester) async {
    await pasangVa(tester, [_respons(alasan: 'belum_diterbitkan', pesan: 'VA belum diterbitkan pengelola.')]);

    expect(find.text('VA belum diterbitkan pengelola.'), findsOneWidget);
    expect(find.text('Nomor Virtual Account'), findsNothing);
    expect(find.text('Cara bayar'), findsNothing);
    expect(find.text('Lihat Riwayat Pembayaran'), findsOneWidget);
  });

  testWidgets('invoice lama: pesan + tombol membuka layar VA invoice yang memegang nomor VA', (tester) async {
    final repo = await pasangVa(tester, [
      _respons(
        alasan: 'invoice_lama',
        pesan: 'Nomor VA unit Anda kini dipakai untuk invoice yang lebih baru.',
        vaAktifDi: {'id_billing': 42035, 'nomor': 'INV/BARU/1'},
      ),
      _respons(va: _va()),
    ]);
    expect(find.textContaining('invoice yang lebih baru'), findsOneWidget);

    await tester.tap(find.text('Buka INV/BARU/1'));
    await tester.pumpAndSettle();

    expect(repo.panggilan, 2);
    expect(find.text('1977012122121953'), findsOneWidget);
  });

  testWidgets('tarik-untuk-segarkan memuat ulang status VA dan mengabarkan pembayaran yang masuk', (tester) async {
    final repo = await pasangVa(tester, [
      _respons(va: _va()),
      _respons(va: _va(status: 'dibayar', dapatDibayar: false, dibayarPada: '2026-11-02 10:00:00', jumlahDibayar: 1212600)),
    ]);
    expect(find.text('BELUM DIBAYAR'), findsOneWidget);

    await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(repo.panggilan, 2);
    expect(find.text('SUDAH DIBAYAR'), findsOneWidget);
    expect(find.text('Pembayaran sudah kami terima.'), findsOneWidget);
  });

  testWidgets('Lihat Riwayat Pembayaran membuka layar riwayat', (tester) async {
    await pasangVa(tester, [_respons(va: _va())]);

    await tester.scrollUntilVisible(find.text('Lihat Riwayat Pembayaran'), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Lihat Riwayat Pembayaran'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Riwayat Pembayaran'), findsOneWidget);
  });

  Map<String, dynamic> detail({required bool lunas}) => {
    'invoice': 'INV/EPR-IPL/5445/X/2026',
    'tanggal_terbit': '2026-10-01',
    'items': [
      {'nama_tag': 'IPL', 'jumlah': 1000000.0, 'status': 1, 'tanggal': '2026-10-01'},
      if (lunas) {'nama_tag': 'IPL', 'jumlah': 1000000.0, 'status': 2, 'tanggal': '2026-10-05'},
    ],
  };

  Future<void> pasangDetail(WidgetTester tester, bool lunas) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tagihanDetailProvider('42034').overrideWith((ref) async => TagihanDetail.fromJson(detail(lunas: lunas), '42034')),
          vaRepositoryProvider.overrideWithValue(_RepoVaPalsu([_respons(va: _va())])),
        ],
        child: MaterialApp(theme: AppTheme.light(), home: const TagihanDetailScreen(id: '42034')),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('detail tagihan belum lunas: tombol Bayar via VA membuka layar VA untuk invoice itu', (tester) async {
    await pasangDetail(tester, false);

    await tester.tap(find.text('Bayar via VA'));
    await tester.pumpAndSettle();

    expect(find.text('Bayar via Virtual Account'), findsOneWidget);
    expect(find.text('1977012122121953'), findsOneWidget);
  });

  testWidgets('detail tagihan lunas: tombol Bayar via VA tidak muncul', (tester) async {
    await pasangDetail(tester, true);

    expect(find.text('Bayar via VA'), findsNothing);
  });
}
