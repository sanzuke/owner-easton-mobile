import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../features/notifikasi/data/notifikasi_repository.dart';
import 'push_backend.dart';

/// Pendaftaran perangkat untuk push notification (FCM) ke backend Laravel
/// (`POST/DELETE /device-token`, docs/96b §11b).
///
/// Aturan dari backend: inbox (`/notifikasi`) adalah sumber kebenaran, push
/// hanya pemicu. Karena itu [onForeground]/[onDibuka] hanya menyegarkan badge /
/// membuka inbox, tidak menyimpan isi push.
///
/// Semua kegagalan (izin ditolak, FCM/Firebase tak tersedia, jaringan) ditelan:
/// push tidak boleh merusak alur login/logout.
class PushService {
  PushService({
    required PushBackend backend,
    required NotifikasiRepository repository,
    String? Function()? platform,
    String? appVersion,
    this.onForeground,
    this.onDibuka,
  })  : _backend = backend,
        _repo = repository,
        _platform = platform ?? _platformDefault,
        _appVersion = appVersion;

  final PushBackend _backend;
  final NotifikasiRepository _repo;
  final String? Function() _platform;
  final String? _appVersion;

  /// Pesan masuk saat app terbuka.
  void Function(PushMessage)? onForeground;

  /// Notifikasi diketuk (app di background atau tertutup).
  void Function(PushMessage)? onDibuka;

  final List<StreamSubscription<dynamic>> _subs = [];
  String? _tokenTerdaftar;
  bool _berjalan = false;

  @visibleForTesting
  String? get tokenTerdaftar => _tokenTerdaftar;

  static String? _platformDefault() => switch (defaultTargetPlatform) {
        TargetPlatform.android => 'android',
        TargetPlatform.iOS => 'ios',
        _ => null, // desktop: tidak ada FCM
      };

  /// Dipanggil sekali setelah login berhasil dan app utama tampil. Aman dipanggil berulang.
  Future<void> mulai() async {
    if (_berjalan) return;
    final platform = _platform();
    if (platform == null) return;
    _berjalan = true;

    try {
      final diizinkan = await _backend.requestPermission();
      if (!diizinkan) {
        // Tanpa izin OS tidak akan menampilkan notifikasi; jangan daftarkan token.
        _berjalan = false;
        return;
      }
      _subs
        ..add(_backend.onTokenRefresh.listen((t) => _daftarkan(t, platform)))
        ..add(_backend.onForegroundMessage.listen((m) => onForeground?.call(m)))
        ..add(_backend.onOpenedFromBackground.listen((m) => onDibuka?.call(m)));

      final token = await _backend.getToken();
      if (token != null && token.isNotEmpty) await _daftarkan(token, platform);

      final awal = await _backend.getInitialMessage();
      if (awal != null) onDibuka?.call(awal);
    } catch (e) {
      debugPrint('Push tidak aktif: $e');
      await _bersihkanLangganan();
      _berjalan = false;
    }
  }

  Future<void> _daftarkan(String token, String platform) async {
    try {
      await _repo.daftarkanPerangkat(token: token, platform: platform, appVersion: _appVersion);
      _tokenTerdaftar = token;
    } catch (e) {
      debugPrint('Gagal mendaftarkan token push: $e');
    }
  }

  /// Dipanggil SEBELUM token login dihapus (logout): lepas token dari akun ini
  /// di backend dan buang token FCM lokal supaya akun berikutnya di HP yang
  /// sama mendapat token baru, bukan push milik akun lama.
  Future<void> berhenti() async {
    await _bersihkanLangganan();
    final token = _tokenTerdaftar;
    _tokenTerdaftar = null;
    _berjalan = false;
    try {
      if (token != null) await _repo.lepasPerangkat(token);
    } catch (e) {
      debugPrint('Gagal melepas token push: $e');
    }
    try {
      await _backend.deleteToken();
    } catch (_) {}
  }

  Future<void> _bersihkanLangganan() async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
  }
}
