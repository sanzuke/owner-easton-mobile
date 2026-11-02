import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../data/berkas_acara.dart';

/// Menulis berkas hasil unduhan ke folder sementara lalu membukanya dengan aplikasi pembaca
/// perangkat (PDF/Word). Dipisah dari layar supaya bisa diganti di tes.
class PembukaBerkas {
  const PembukaBerkas();

  /// `true` bila ada aplikasi yang membuka berkas.
  Future<bool> buka(Uint8List bytes, {required String nama, required JenisBerkas jenis}) async {
    final tmp = await getTemporaryDirectory();
    final dir = Directory('${tmp.path}/acara_berkas');
    await dir.create(recursive: true);
    final file = File('${dir.path}/$nama.${jenis.ekstensi}');
    await file.writeAsBytes(bytes, flush: true);
    final hasil = await OpenFilex.open(file.path, type: jenis.mime);
    return hasil.type == ResultType.done;
  }
}

final pembukaBerkasProvider = Provider<PembukaBerkas>((ref) => const PembukaBerkas());
