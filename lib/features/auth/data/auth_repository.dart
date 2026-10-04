import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_token_storage.dart';

/// Hasil `POST /auth/login` yang sukses.
class LoginResult {
  /// `true` bila owner masih memakai password default (6 digit terakhir NIK)
  /// dan WAJIB menggantinya sebelum memakai app.
  final bool mustChangePassword;
  const LoginResult({required this.mustChangePassword});
}

/// Repository auth — bicara ke endpoint `/api/v1/auth/*` (docs/96b §4).
/// Login memakai password (OTP WA sudah dicabut); password dipakai bersama
/// portal web owner.
class AuthRepository {
  AuthRepository({required ApiClient apiClient, required SecureTokenStorage tokenStorage})
      : _api = apiClient,
        _tokenStorage = tokenStorage;

  final ApiClient _api;
  final SecureTokenStorage _tokenStorage;

  /// No WA terdaftar + unit + password → simpan Sanctum token. Bila backend
  /// menandai `must_change_password`, penanda lokal dipasang supaya app tetap
  /// memaksa ganti password walau ditutup di tengah jalan.
  Future<LoginResult> login({
    required String noHp,
    required String idBast,
    required String password,
  }) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'hp': noHp, 'id_bast': idBast, 'password': password},
      fromData: (json) => json as Map<String, dynamic>,
    );
    final token = res.data?['token']?.toString();
    if (token == null || token.isEmpty) {
      throw StateError('Token tidak ditemukan pada respons login.');
    }
    final mustChange = res.data?['must_change_password'] == true;
    await _tokenStorage.saveToken(token);
    await _tokenStorage.setPasswordChangePending(mustChange);
    return LoginResult(mustChangePassword: mustChange);
  }

  /// Ganti password. `currentPassword` tidak diminta backend saat
  /// wajib-ganti (password default), selain itu wajib.
  Future<void> changePassword({
    String? currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _api.post<void>(
      '/auth/ganti-password',
      data: {
        if (currentPassword != null && currentPassword.isNotEmpty)
          'current_password': currentPassword,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      },
    );
    await _tokenStorage.setPasswordChangePending(false);
  }

  /// Minta link reset password ke email terdaftar. Mengembalikan pesan dari
  /// server (sudah siap tampil).
  Future<String> forgotPassword({required String noHp, required String idBast}) async {
    final res = await _api.post<Object?>(
      '/auth/lupa-password',
      data: {'hp': noHp, 'id_bast': idBast},
    );
    return res.message;
  }

  Future<bool> isLoggedIn() async {
    final token = await _tokenStorage.readToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } finally {
      await _tokenStorage.clearToken();
      await _tokenStorage.setBiometricEnabled(false);
      await _tokenStorage.setPasswordChangePending(false);
    }
  }
}
