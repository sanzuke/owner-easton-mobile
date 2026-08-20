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
}
