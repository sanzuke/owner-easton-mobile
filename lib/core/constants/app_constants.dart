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

  /// Key penanda: login terakhir memakai password default dan owner belum
  /// menggantinya (backend `must_change_password`). Selama true, app selalu
  /// diarahkan ke layar ganti password.
  static const String prefsPasswordChangePendingKey = 'password_change_pending';

  /// Key preferensi tampilan dashboard (otomatis / nyaman / modern).
  static const String prefsTampilanKey = 'tampilan_dashboard';

  /// Key preferensi tema warna (sistem / terang / gelap).
  static const String prefsTemaKey = 'tema_warna';

  /// Kontak Tenant Relation (sama dengan pesan error login di API).
  static const String kontakPengelola = '082312122021';
  static const String kontakPengelolaTampil = '0823-1212-2021';
}
