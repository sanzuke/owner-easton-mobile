import 'package:flutter/material.dart' show Brightness, ThemeMode;
import 'package:owner_easton_mobile/features/dashboard/presentation/dash_palette.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:owner_easton_mobile/core/theme/tampilan.dart';

void main() {
  final sekarang = DateTime(2026, 10, 8);

  group('usia & tema otomatis', () {
    test('usia dihitung penuh, belum ulang tahun dikurangi satu', () {
      expect(hitungUsia(DateTime(1971, 10, 8), sekarang), 55);
      expect(hitungUsia(DateTime(1971, 10, 9), sekarang), 54);
    });

    test('batas 55 tahun: ke atas Nyaman, di bawahnya Modern', () {
      expect(modeOtomatis(DateTime(1971, 10, 8), sekarang), TampilanMode.nyaman);
      expect(modeOtomatis(DateTime(1971, 10, 9), sekarang), TampilanMode.modern);
      expect(modeOtomatis(DateTime(1995, 1, 1), sekarang), TampilanMode.modern);
    });

    test('tanggal lahir tidak diketahui -> Nyaman', () {
      expect(modeOtomatis(null, sekarang), TampilanMode.nyaman);
    });

    test('pilihan manual mengalahkan usia', () {
      expect(modeEfektif(TampilanPilihan.modern, DateTime(1950, 1, 1), sekarang), TampilanMode.modern);
      expect(modeEfektif(TampilanPilihan.nyaman, DateTime(2000, 1, 1), sekarang), TampilanMode.nyaman);
      expect(modeEfektif(TampilanPilihan.otomatis, DateTime(2000, 1, 1), sekarang), TampilanMode.modern);
    });

    test('nilai tersimpan yang rusak jatuh ke otomatis', () {
      expect(TampilanPilihan.dari('modern'), TampilanPilihan.modern);
      expect(TampilanPilihan.dari('aneh'), TampilanPilihan.otomatis);
      expect(TampilanPilihan.dari(null), TampilanPilihan.otomatis);
    });
  });

  group('tema warna', () {
    test('pilihan dipetakan ke ThemeMode; nilai rusak/kosong ikut HP', () {
      expect(TemaPilihan.dari('gelap').mode, ThemeMode.dark);
      expect(TemaPilihan.dari('terang').mode, ThemeMode.light);
      expect(TemaPilihan.dari('sistem').mode, ThemeMode.system);
      expect(TemaPilihan.dari('aneh'), TemaPilihan.sistem);
      expect(TemaPilihan.dari(null), TemaPilihan.sistem);
    });

    test('semua gaya mengikuti kecerahan; Modern tidak lagi dipaksa gelap', () {
      expect(DashPalette.untuk(TampilanMode.modern, Brightness.light), DashPalette.modernTerang);
      expect(DashPalette.untuk(TampilanMode.modern, Brightness.dark), DashPalette.modernGelap);
      expect(DashPalette.untuk(TampilanMode.nyaman, Brightness.light), DashPalette.nyamanTerang);
      expect(DashPalette.untuk(TampilanMode.nyaman, Brightness.dark), DashPalette.nyamanGelap);
    });
  });

  group('sapaan', () {
    test('nama panggilan membuang gelar depan/belakang dan merapikan huruf', () {
      expect(namaPanggilan('Murleni, ST'), 'Murleni');
      expect(namaPanggilan('Dr. Hasan Basri'), 'Hasan');
      expect(namaPanggilan('H. BUDI SANTOSO'), 'Budi');
      expect(namaPanggilan('Ir Amas Wijaya'), 'Amas');
      expect(namaPanggilan(null), '');
    });

    test('sebutan dari jenis kelamin', () {
      expect(sebutan('Laki-laki'), 'Bapak');
      expect(sebutan('Perempuan'), 'Ibu');
      expect(sebutan(null), 'Bapak/Ibu');
    });

    test('sapaan menurut jam', () {
      expect(sapaanWaktu(DateTime(2026, 1, 1, 7)), 'Selamat Pagi');
      expect(sapaanWaktu(DateTime(2026, 1, 1, 12)), 'Selamat Siang');
      expect(sapaanWaktu(DateTime(2026, 1, 1, 16)), 'Selamat Sore');
      expect(sapaanWaktu(DateTime(2026, 1, 1, 20)), 'Selamat Malam');
    });
  });
}
