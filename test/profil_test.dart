import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:owner_easton_mobile/core/theme/app_theme.dart';
import 'package:owner_easton_mobile/features/dashboard/application/dashboard_providers.dart';
import 'package:owner_easton_mobile/features/profil/application/profil_providers.dart';
import 'package:owner_easton_mobile/features/profil/data/profil_repository.dart';
import 'package:owner_easton_mobile/features/profil/presentation/profil_screen.dart';

// JSON mengikuti GET /api/v1/profil (docs/96b §8).
final _json = {
  'nama': 'Budi Santoso',
  'nik': '3205xxxxxxxxxxxx',
  'hp': '081234567890',
  'email': 'budi@mail.com',
  'alamat': 'Jl. Mawar No. 1, Jatinangor',
  'jenis_kelamin': 'L',
  'tempat_lahir': 'Bandung',
  'tanggal_lahir': '1960-05-02',
  'foto_url': null,
  'berkas': {
    'ktp': {'file': 'ktp.jpg', 'diunggah_pada': '2026-08-10 10:00:00'},
    'kartu_keluarga': null,
  },
};

Widget _app(Map<String, dynamic> json, {bool gelap = false}) => ProviderScope(
      overrides: [
        profilProvider.overrideWith((ref) async => Profil.fromJson(json)),
        dashboardSummaryProvider.overrideWith((ref) => Future.error('tanpa jaringan')),
      ],
      child: MaterialApp(theme: gelap ? AppTheme.dark() : AppTheme.light(), home: const ProfilScreen()),
    );

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  test('model profil: foto, berkas, dan tanggal lahir tidak valid', () {
    final p = Profil.fromJson(_json);
    expect(p.fotoUrl, isNull);
    expect(p.ktp?.diunggahPada, DateTime(2026, 8, 10, 10));
    expect(p.kartuKeluarga, isNull);
    expect(p.tanggalLahir, DateTime(1960, 5, 2));
    expect(Profil.fromJson({..._json, 'tanggal_lahir': '0000-00-00'}).tanggalLahir, isNull);
  });

  testWidgets('tampilan profil: data pribadi dan status dokumen', (tester) async {
    await tester.pumpWidget(_app(_json));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Budi Santoso'), findsOneWidget);
    expect(find.text('081234567890'), findsOneWidget);
    expect(find.text('Laki-laki'), findsOneWidget);
    expect(find.textContaining('Bandung, 2 Mei 1960'), findsOneWidget);
    expect(find.text('Belum diunggah'), findsOneWidget); // KK
    expect(find.textContaining('Diunggah 10'), findsOneWidget); // KTP
    expect(find.text('Ganti'), findsOneWidget);
    expect(find.text('Unggah'), findsOneWidget);
  });

  testWidgets('mode edit: tombol Batal dan Simpan berukuran sama', (tester) async {
    tester.view.physicalSize = const Size(900, 2200);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(_json));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Edit Profil'));
    await tester.pumpAndSettle();

    final batal = tester.getSize(find.widgetWithText(OutlinedButton, 'Batal'));
    final simpan = tester.getSize(find.widgetWithText(FilledButton, 'Simpan'));
    expect(batal, simpan);
    expect(simpan.height, 52);
  });
}
