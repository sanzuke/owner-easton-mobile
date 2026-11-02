import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:owner_easton_mobile/core/pagination/daftar_berhalaman.dart';
import 'package:owner_easton_mobile/core/theme/app_theme.dart';
import 'package:owner_easton_mobile/features/dashboard/application/dashboard_providers.dart';
import 'package:owner_easton_mobile/features/pbb/application/pbb_providers.dart';
import 'package:owner_easton_mobile/features/pbb/data/pbb_repository.dart';
import 'package:owner_easton_mobile/features/pbb/presentation/pbb_screen.dart';
import 'package:owner_easton_mobile/features/profil/application/profil_providers.dart';
import 'package:owner_easton_mobile/features/profil/data/profil_repository.dart';
import 'package:owner_easton_mobile/features/profil/presentation/profil_screen.dart';
import 'package:owner_easton_mobile/features/tagihan/application/tagihan_providers.dart';
import 'package:owner_easton_mobile/features/tagihan/data/tagihan_repository.dart';
import 'package:owner_easton_mobile/features/tagihan/presentation/tagihan_list_screen.dart';

/// Audit `Row` berisi tombol (2 Nov 2026): tema app memberi FilledButton/ElevatedButton
/// `minimumSize: Size.fromHeight(52)` (lebar tak hingga) sehingga tombol di dalam `Row` tanpa
/// `Expanded`/`minimumSize` lokal memicu "BoxConstraints forces an infinite width" dan layar
/// kosong. Tes ini memakai tema ASLI pada layar sempit untuk layar yang memuat Row tombol.
/// (Font tes `Ahem` lebih lebar dari font nyata, jadi lebar uji dipilih konservatif.)

class _RepoTagihanPalsu implements TagihanRepository {
  @override
  Future<Halaman<Tagihan>> getHalaman(int halaman, Periode? periode) async => const Halaman([
        Tagihan(id: '9', nomorInvoice: 'INV/9', periode: '2026-07-01', total: 500000, status: 'Belum lunas'),
      ], 1);

  @override
  Future<TagihanDetail> getDetail(String id) => throw UnimplementedError();
}

Future<void> _ukuran(WidgetTester tester, double lebar) async {
  await initializeDateFormatting('id_ID');
  tester.view.physicalSize = Size(lebar, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  for (final lebar in [320.0, 360.0]) {
    testWidgets('PBB: baris SPPT (Lihat) dan bukti bayar (Lihat+ganti+hapus / Unggah) pada lebar ${lebar.toInt()}', (tester) async {
      await _ukuran(tester, lebar);
      const data = PbbData(tersedia: true, nop: '32.05.123', items: [
        PbbTahun(idDetail: 11, tahun: 2026, tagihan: 1250000, lunas: false, adaPdf: true, adaBukti: true),
        PbbTahun(idDetail: 10, tahun: 2025, tagihan: 1250000, lunas: false, adaPdf: true, adaBukti: false),
      ]);
      await tester.pumpWidget(ProviderScope(
        overrides: [pbbProvider.overrideWith((ref) async => data)],
        child: MaterialApp(theme: AppTheme.light(), home: const PbbScreen()),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Lihat'), findsNWidgets(3));
      expect(find.text('Unggah'), findsOneWidget);
    });

    testWidgets('Profil: baris dokumen identitas (Ganti / Unggah) pada lebar ${lebar.toInt()}', (tester) async {
      await _ukuran(tester, lebar);
      final profil = Profil.fromJson({
        'nama': 'Budi Santoso', 'hp': '081234567890', 'email': 'budi@mail.com', 'alamat': 'Jl. Mawar No. 1',
        'jenis_kelamin': 'L', 'tempat_lahir': 'Bandung', 'tanggal_lahir': '1960-05-02',
        'berkas': {'ktp': {'file': 'ktp.jpg', 'diunggah_pada': '2026-08-10 10:00:00'}, 'kartu_keluarga': null},
      });
      await tester.pumpWidget(ProviderScope(
        overrides: [
          profilProvider.overrideWith((ref) async => profil),
          dashboardSummaryProvider.overrideWith((ref) => Future.error('tanpa jaringan')),
        ],
        child: MaterialApp(theme: AppTheme.light(), home: const ProfilScreen()),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Ganti'), findsOneWidget);
      expect(find.text('Unggah'), findsOneWidget);
    });

    testWidgets('Tagihan: kartu invoice dengan tombol Print di Row pada lebar ${lebar.toInt()}', (tester) async {
      await _ukuran(tester, lebar);
      await tester.pumpWidget(ProviderScope(
        overrides: [tagihanRepositoryProvider.overrideWithValue(_RepoTagihanPalsu())],
        child: MaterialApp(theme: AppTheme.light(), home: const TagihanListScreen()),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Print'), findsOneWidget);
    });
  }
}
