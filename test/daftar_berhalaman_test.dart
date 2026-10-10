import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:owner_easton_mobile/core/pagination/daftar_berhalaman.dart';
import 'package:owner_easton_mobile/features/pembayaran/application/pembayaran_providers.dart';
import 'package:owner_easton_mobile/features/pembayaran/data/pembayaran_repository.dart';
import 'package:owner_easton_mobile/features/pembayaran/presentation/pembayaran_screen.dart';

/// Server palsu: 3 halaman @ 4 baris, kwitansi `K{halaman}-{n}`; mencatat periode & halaman yang diminta.
class _RepoPalsu implements PembayaranRepository {
  final diminta = <(int, Periode?)>[];
  int gagalDiHalaman = 0;
  int lastPage = 3;

  @override
  Future<Halaman<RiwayatBayar>> getHalaman(int halaman, Periode? periode) async {
    diminta.add((halaman, periode));
    if (halaman == gagalDiHalaman) {
      gagalDiHalaman = 0; // gagal sekali saja
      throw Exception('jaringan putus');
    }
    return Halaman([
      for (var i = 1; i <= 4; i++)
        RiwayatBayar(id: '$halaman$i', kwitansi: 'K$halaman-$i', jumlah: 1000, metode: 'BANK', tanggal: DateTime(2026, 3, i)),
    ], lastPage);
  }
}

ProviderContainer _kontainer(_RepoPalsu repo) {
  final c = ProviderContainer(overrides: [pembayaranRepositoryProvider.overrideWithValue(repo)]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  test('muatLagi menambah halaman berikutnya sampai halaman terakhir lalu berhenti', () async {
    final repo = _RepoPalsu();
    final c = _kontainer(repo);
    final sub = c.listen(riwayatBayarProvider, (_, _) {});
    addTearDown(sub.close);

    await c.read(riwayatBayarProvider.future);
    final n = c.read(riwayatBayarProvider.notifier);
    await n.muatLagi();
    await n.muatLagi();
    await n.muatLagi(); // halaman terakhir sudah tercapai: tidak ada request ke-4

    final s = c.read(riwayatBayarProvider).requireValue;
    expect(s.items.map((e) => e.kwitansi).toList().sublist(3, 6), ['K1-4', 'K2-1', 'K2-2']);
    expect(s.items, hasLength(12));
    expect(s.adaLagi, isFalse);
    expect(repo.diminta.map((e) => e.$1), [1, 2, 3]);
  });

  test('halaman gagal dimuat: daftar lama dipertahankan, bisa dicoba lagi tanpa duplikat', () async {
    final repo = _RepoPalsu()..gagalDiHalaman = 2;
    final c = _kontainer(repo);
    final sub = c.listen(riwayatBayarProvider, (_, _) {});
    addTearDown(sub.close);
    await c.read(riwayatBayarProvider.future);
    final n = c.read(riwayatBayarProvider.notifier);

    await n.muatLagi();
    var s = c.read(riwayatBayarProvider).requireValue;
    expect(s.gagalMuatLagi, isTrue);
    expect(s.items, hasLength(4));

    await n.muatLagi();
    s = c.read(riwayatBayarProvider).requireValue;
    expect(s.gagalMuatLagi, isFalse);
    expect(s.items, hasLength(8));
  });

  test('ganti periode memuat ulang dari halaman 1 dengan filter dikirim ke server', () async {
    final repo = _RepoPalsu();
    final c = _kontainer(repo);
    final sub = c.listen(riwayatBayarProvider, (_, _) {});
    addTearDown(sub.close);
    await c.read(riwayatBayarProvider.future);
    await c.read(riwayatBayarProvider.notifier).muatLagi();

    final p = Periode(DateTime(2026, 3, 1), DateTime(2026, 3, 31));
    c.read(periodePembayaranProvider.notifier).state = p;
    await c.read(riwayatBayarProvider.future);

    expect(repo.diminta.last, (1, p));
    expect(c.read(riwayatBayarProvider).requireValue.items, hasLength(4));
    expect(p.query, {'dari': '2026-03-01', 'sampai': '2026-03-31'});
  });

  testWidgets('layar: menggulir ke bawah memuat halaman berikutnya otomatis', (tester) async {
    final repo = _RepoPalsu();
    await tester.pumpWidget(ProviderScope(
      overrides: [pembayaranRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: [Locale('id'), Locale('en')],
        home: PembayaranScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    expect(repo.diminta.map((e) => e.$1), [1]);
    expect(find.text('Semua periode'), findsOneWidget);

    // 4 kartu tidak memenuhi layar uji 800px? Perkecil layar agar daftar bisa digulir.
    tester.view.physicalSize = const Size(400, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView).last, const Offset(0, -2000));
    await tester.pumpAndSettle();

    expect(repo.diminta.map((e) => e.$1), contains(2));
  });

  Future<void> pasangKosong(WidgetTester tester, {Periode? periode}) async {
    await tester.pumpWidget(ProviderScope(
      key: UniqueKey(),
      overrides: [
        pembayaranRepositoryProvider.overrideWithValue(_KosongRepo()),
        if (periode != null) periodePembayaranProvider.overrideWith((ref) => periode),
      ],
      child: const MaterialApp(
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: [Locale('id'), Locale('en')],
        home: PembayaranScreen(),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('layar: kosong tanpa filter = pesan umum; kosong dengan periode = pesan periode + chip rentang', (tester) async {
    await pasangKosong(tester);
    expect(find.text('Belum ada riwayat pembayaran.'), findsOneWidget);

    await pasangKosong(tester, periode: Periode(DateTime(2026, 3, 1), DateTime(2026, 3, 31)));
    expect(find.text('Tidak ada pembayaran pada periode ini.'), findsOneWidget);
    expect(find.text('1 Mar 2026 – 31 Mar 2026'), findsOneWidget);
  });
}

class _KosongRepo implements PembayaranRepository {
  @override
  Future<Halaman<RiwayatBayar>> getHalaman(int halaman, Periode? periode) async => const Halaman([], 1);
}
