/// Konstanta global aplikasi Owner Easton Park.
///
/// Nilai API base URL diambil dari .env (lihat lib/core/env/env.dart),
/// bukan di-hardcode di sini — supaya gampang beda-beda antara dev/staging/
/// production tanpa rebuild kode.
class AppConstants {
  AppConstants._();

  static const String appName = 'Owner Easton Park';

  /// Prefix versi API — lihat docs/96_perencanaan_mobile_app_owner.md §3:
  /// "Versioning API: prefix /api/v1/... sejak awal".
  static const String apiVersionPrefix = '/api/v1';

  /// Key penyimpanan token Sanctum di secure storage.
  static const String secureStorageTokenKey = 'sanctum_token';

  /// Key preferensi lokal: apakah user mengaktifkan buka cepat biometrik.
  static const String prefsBiometricEnabledKey = 'biometric_enabled';
}
