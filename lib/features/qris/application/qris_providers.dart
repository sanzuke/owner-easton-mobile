import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/providers/core_providers.dart';
import '../data/qris_repository.dart';

final qrisRepositoryProvider = Provider<QrisRepository>(
  (ref) => QrisRepository(apiClient: ref.watch(apiClientProvider)),
);

/// Menyimpan/membagikan gambar QR lewat lembar bagikan perangkat (pengguna bisa memilih "Simpan ke galeri/berkas").
/// Dipisah dari layar supaya bisa diganti di tes.
class PembagiQr {
  const PembagiQr();

  Future<void> bagikan(Uint8List png, {required String nama}) async {
    final tmp = await getTemporaryDirectory();
    final dir = Directory('${tmp.path}/qris');
    await dir.create(recursive: true);
    final file = File('${dir.path}/$nama.png');
    await file.writeAsBytes(png, flush: true);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path, mimeType: 'image/png')], text: 'QRIS pembayaran Easton Park'),
    );
  }
}

final pembagiQrProvider = Provider<PembagiQr>((ref) => const PembagiQr());
