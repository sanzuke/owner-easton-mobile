import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';

/// Penyimpanan token Sanctum di secure storage (Keychain/Keystore) — bukan
/// SharedPreferences, supaya token tidak mudah dibaca dari device yang
/// di-root/jailbreak. Lihat docs/96 §3 (flutter_secure_storage).
class SecureTokenStorage {
  SecureTokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<void> saveToken(String token) =>
      _storage.write(key: AppConstants.secureStorageTokenKey, value: token);

  Future<String?> readToken() =>
      _storage.read(key: AppConstants.secureStorageTokenKey);

  Future<void> clearToken() =>
      _storage.delete(key: AppConstants.secureStorageTokenKey);

  /// Preferensi buka cepat biometrik. Disimpan di secure storage yang sama
  /// dengan token supaya hilang bersama-sama saat logout.
  Future<bool> isBiometricEnabled() async =>
      await _storage.read(key: AppConstants.prefsBiometricEnabledKey) == 'true';

  Future<void> setBiometricEnabled(bool enabled) => enabled
      ? _storage.write(key: AppConstants.prefsBiometricEnabledKey, value: 'true')
      : _storage.delete(key: AppConstants.prefsBiometricEnabledKey);

  /// Penanda wajib-ganti-password (login pertama dengan password default).
  Future<bool> isPasswordChangePending() async =>
      await _storage.read(key: AppConstants.prefsPasswordChangePendingKey) == 'true';

  Future<void> setPasswordChangePending(bool pending) => pending
      ? _storage.write(key: AppConstants.prefsPasswordChangePendingKey, value: 'true')
      : _storage.delete(key: AppConstants.prefsPasswordChangePendingKey);

  /// Pilihan tampilan dashboard ('otomatis' | 'nyaman' | 'modern'); null = belum pernah dipilih.
  Future<String?> readTampilan() => _storage.read(key: AppConstants.prefsTampilanKey);

  Future<void> saveTampilan(String value) =>
      _storage.write(key: AppConstants.prefsTampilanKey, value: value);
}
