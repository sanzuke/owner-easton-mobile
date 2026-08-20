import 'package:local_auth/local_auth.dart';

/// Buka cepat via fingerprint/Face ID/deteksi wajah Android — device-level,
/// bukan face-recognition server-side (lihat docs/96 §3). Hanya berfungsi
/// sebagai gerbang lokal untuk membuka token Sanctum yang sudah tersimpan;
/// tidak pernah mengirim data biometrik ke server.
class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  Future<bool> isDeviceSupported() async {
    final canCheck = await _localAuth.canCheckBiometrics;
    final isSupported = await _localAuth.isDeviceSupported();
    return canCheck && isSupported;
  }

  Future<bool> authenticate() async {
    return _localAuth.authenticate(
      localizedReason: 'Verifikasi identitas untuk membuka aplikasi',
      options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
    );
  }
}
