import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Rentang tanggal inklusif untuk filter periode (`dari`/`sampai` di API, format `yyyy-MM-dd`).
class Periode {
  const Periode(this.dari, this.sampai);

  final DateTime dari;
  final DateTime sampai;

  Map<String, String> get query {
    final f = DateFormat('yyyy-MM-dd');
    return {'dari': f.format(dari), 'sampai': f.format(sampai)};
  }

  @override
  bool operator ==(Object other) =>
      other is Periode && other.dari == dari && other.sampai == sampai;

  @override
  int get hashCode => Object.hash(dari, sampai);
}

/// Satu halaman hasil API (`data.items` + `data.pagination.last_page`).
class Halaman<T> {
  const Halaman(this.items, this.lastPage);

  final List<T> items;
  final int lastPage;

  /// Membaca respons `data: {items: [...], pagination: {last_page}}`; `last_page` hilang dianggap 1.
  factory Halaman.dariJson(
    Object? json,
    T Function(Map<String, dynamic>) baris,
  ) {
    final data = json as Map<String, dynamic>;
    final pg = data['pagination'];
    return Halaman(
      ((data['items'] as List?) ?? const [])
          .map((e) => baris(e as Map<String, dynamic>))
          .toList(growable: false),
      pg is Map ? (int.tryParse(pg['last_page']?.toString() ?? '') ?? 1) : 1,
    );
  }
}

class DaftarBerhalaman<T> {
  const DaftarBerhalaman({
    required this.items,
    required this.halaman,
    required this.lastPage,
    this.memuatLagi = false,
    this.gagalMuatLagi = false,
  });

  final List<T> items;
  final int halaman;
  final int lastPage;
  final bool memuatLagi;

  /// Halaman berikutnya gagal dimuat; daftar yang sudah ada tetap tampil dan bisa dicoba lagi.
  final bool gagalMuatLagi;

  bool get adaLagi => halaman < lastPage;

  DaftarBerhalaman<T> copyWith({bool? memuatLagi, bool? gagalMuatLagi}) =>
      DaftarBerhalaman(
        items: items,
        halaman: halaman,
        lastPage: lastPage,
        memuatLagi: memuatLagi ?? this.memuatLagi,
        gagalMuatLagi: gagalMuatLagi ?? this.gagalMuatLagi,
      );
}

/// Dasar daftar infinite scroll: [build] memuat halaman 1 (state loading/error bawaan AsyncNotifier),
/// [muatLagi] menambahkan halaman berikutnya. Filter diikuti dengan `ref.watch` di [periodeAktif]
/// sehingga mengubah filter memuat ulang dari halaman 1.
abstract class DaftarBerhalamanNotifier<T>
    extends AutoDisposeAsyncNotifier<DaftarBerhalaman<T>> {
  /// Dipanggil dari `build` — gunakan `ref.watch(...)` agar perubahan filter memicu muat ulang.
  Periode? periodeAktif();

  Future<Halaman<T>> ambil(int halaman, Periode? periode);

  Periode? _periode;

  @override
  Future<DaftarBerhalaman<T>> build() async {
    _periode = periodeAktif();
    final h = await ambil(1, _periode);
    return DaftarBerhalaman(items: h.items, halaman: 1, lastPage: h.lastPage);
  }

  Future<void> muatLagi() async {
    final s = state.valueOrNull;
    if (s == null || !s.adaLagi || s.memuatLagi) return;
    state = AsyncData(s.copyWith(memuatLagi: true, gagalMuatLagi: false));
    try {
      final h = await ambil(s.halaman + 1, _periode);
      state = AsyncData(
        DaftarBerhalaman(
          items: [...s.items, ...h.items],
          halaman: s.halaman + 1,
          lastPage: h.lastPage,
        ),
      );
    } catch (_) {
      state = AsyncData(s.copyWith(memuatLagi: false, gagalMuatLagi: true));
    }
  }
}
