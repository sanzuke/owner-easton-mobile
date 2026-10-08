import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/navigator_keys.dart';
import '../../features/notifikasi/application/notifikasi_providers.dart';
import '../../features/notifikasi/presentation/notifikasi_screen.dart';
import 'push_backend.dart';
import 'push_service.dart';

/// `false` bila Firebase gagal diinisialisasi saat start (mis. `google-services.json`
/// belum dipasang): push dimatikan, aplikasi lain tetap jalan. Diisi di `main()`.
final firebaseSiapProvider = StateProvider<bool>((ref) => false);

final pushServiceProvider = Provider<PushService>((ref) {
  final siap = ref.watch(firebaseSiapProvider);
  final service = PushService(
    // Tanpa Firebase: backend palsu yang menolak izin => mulai() tidak melakukan apa pun.
    backend: siap ? FirebasePushBackend() : _TanpaPush(),
    repository: ref.watch(notifikasiRepositoryProvider),
  );

  service.onForeground = (m) {
    ref.invalidate(notifikasiBelumDibacaProvider);
    ref.invalidate(notifikasiPageProvider);
    final judul = [m.title, m.body].whereType<String>().where((s) => s.isNotEmpty).join(' — ');
    if (judul.isEmpty) return;
    scaffoldMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(judul, maxLines: 2, overflow: TextOverflow.ellipsis),
        action: SnackBarAction(label: 'Lihat', onPressed: _bukaInbox),
      ));
  };
  service.onDibuka = (_) {
    ref.invalidate(notifikasiBelumDibacaProvider);
    _bukaInbox();
  };
  return service;
});

/// Inbox adalah sumber kebenaran (docs/96b §11b), jadi ketukan notifikasi
/// membuka daftar notifikasi.
void _bukaInbox() {
  rootNavigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => const NotifikasiScreen()));
}

class _TanpaPush implements PushBackend {
  @override
  Future<bool> requestPermission() async => false;
  @override
  Future<String?> getToken() async => null;
  @override
  Stream<String> get onTokenRefresh => const Stream.empty();
  @override
  Stream<PushMessage> get onForegroundMessage => const Stream.empty();
  @override
  Stream<PushMessage> get onOpenedFromBackground => const Stream.empty();
  @override
  Future<PushMessage?> getInitialMessage() async => null;
  @override
  Future<void> deleteToken() async {}
}
