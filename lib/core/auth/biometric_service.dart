import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Buka cepat via fingerprint/Face ID/deteksi wajah Android — device-level,
/// bukan face-recognition server-side (lihat docs/96 §3). Hanya berfungsi
/// sebagai gerbang lokal untuk membuka token Sanctum yang sudah tersimpan;
/// tidak pernah mengirim data biometrik ke server.
class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  /// True bila perangkat mendukung DAN sudah ada biometrik yang didaftarkan
  /// (sidik jari / wajah). Tanpa itu opsi buka cepat tidak ditawarkan.
  Future<bool> isAvailable() async {
    try {
      if (!await _localAuth.isDeviceSupported()) return false;
      if (!await _localAuth.canCheckBiometrics) return false;
      return (await _localAuth.getAvailableBiometrics()).isNotEmpty;
    } on PlatformException {
      return false;
    }
  }

  /// Tampilkan prompt biometrik. False bila dibatalkan / gagal / terkunci.
  Future<bool> authenticate({String reason = 'Verifikasi identitas untuk membuka aplikasi'}) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
      );
    } on PlatformException {
      return false;
    }
  }
}
