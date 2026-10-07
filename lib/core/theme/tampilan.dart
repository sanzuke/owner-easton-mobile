/// Pilihan tampilan dashboard yang disimpan pemilik (menu Pengaturan > Tampilan).
enum TampilanPilihan {
  otomatis,
  nyaman,
  modern;

  static TampilanPilihan dari(String? nilai) => TampilanPilihan.values.firstWhere(
        (e) => e.name == nilai,
        orElse: () => TampilanPilihan.otomatis,
      );
}

/// Tampilan yang benar-benar dipakai.
enum TampilanMode { nyaman, modern }

/// Pemilik berusia di atas/sama dengan batas ini mendapat tema Nyaman secara otomatis.
const int batasUsiaNyaman = 55;

/// Usia penuh dalam tahun pada [sekarang]; null bila tanggal lahir tidak diketahui.
int? hitungUsia(DateTime? lahir, DateTime sekarang) {
  if (lahir == null) return null;
  var usia = sekarang.year - lahir.year;
  final belumUlangTahun =
      sekarang.month < lahir.month || (sekarang.month == lahir.month && sekarang.day < lahir.day);
  if (belumUlangTahun) usia--;
  return usia < 0 ? null : usia;
}

/// Tema default menurut usia. Tanggal lahir tidak diketahui -> Nyaman, karena mayoritas
/// pemilik berusia lanjut dan tampilan besar tidak merugikan yang lebih muda.
TampilanMode modeOtomatis(DateTime? lahir, DateTime sekarang) {
  final usia = hitungUsia(lahir, sekarang);
  return (usia == null || usia >= batasUsiaNyaman) ? TampilanMode.nyaman : TampilanMode.modern;
}

/// Pilihan manual mengalahkan default usia.
TampilanMode modeEfektif(TampilanPilihan pilihan, DateTime? lahir, DateTime sekarang) {
  switch (pilihan) {
    case TampilanPilihan.nyaman:
      return TampilanMode.nyaman;
    case TampilanPilihan.modern:
      return TampilanMode.modern;
    case TampilanPilihan.otomatis:
      return modeOtomatis(lahir, sekarang);
  }
}

/// Sapaan menurut jam: Pagi (<11), Siang (<15), Sore (<18), Malam.
String sapaanWaktu(DateTime sekarang) {
  final h = sekarang.hour;
  if (h < 11) return 'Selamat Pagi';
  if (h < 15) return 'Selamat Siang';
  if (h < 18) return 'Selamat Sore';
  return 'Selamat Malam';
}

const _gelar = {'dr', 'drs', 'dra', 'ir', 'h', 'hj', 'prof', 'bpk', 'bapak', 'ibu', 'ny', 'tn', 'mr', 'mrs'};

/// Nama panggilan dari nama lengkap data pemilik: buang gelar belakang (", ST"), gelar depan
/// (Dr., Ir., H.) dan rapikan huruf besar semua ("BUDI SANTOSO" -> "Budi").
String namaPanggilan(String? nama) {
  final bersih = (nama ?? '').split(',').first.trim();
  for (final kata in bersih.split(RegExp(r'\s+'))) {
    final inti = kata.replaceAll('.', '');
    if (inti.isEmpty || _gelar.contains(inti.toLowerCase())) continue;
    return inti[0].toUpperCase() + inti.substring(1).toLowerCase();
  }
  return '';
}

/// "Bapak"/"Ibu" dari jenis kelamin data pemilik; tidak diketahui -> "Bapak/Ibu".
String sebutan(String? jenisKelamin) {
  final j = (jenisKelamin ?? '').toLowerCase();
  if (j.startsWith('l') || j == 'pria') return 'Bapak';
  if (j.startsWith('p') || j == 'wanita') return 'Ibu';
  return 'Bapak/Ibu';
}
