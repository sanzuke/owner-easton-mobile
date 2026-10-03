import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_token_storage.dart';

/// Hasil `POST /auth/login` — backend balas `uid` (identifier sesi OTP,
/// dipakai lagi saat verify-otp), lihat docs/96 update 19 Agustus.
class LoginOtpRequest {
  final String uid;
  const LoginOtpRequest({required this.uid});

  factory LoginOtpRequest.fromJson(Map<String, dynamic> json) =>
      LoginOtpRequest(uid: json['uid'].toString());
}

/// Repository auth — bicara ke endpoint `/api/v1/auth/*` (lihat docs/96 §3
/// dan update 19 Agustus: login → OTP WA → verify-otp → Sanctum token).
class AuthRepository {
  AuthRepository({required ApiClient apiClient, required SecureTokenStorage tokenStorage})
      : _api = apiClient,
        _tokenStorage = tokenStorage;

  final ApiClient _api;
  final SecureTokenStorage _tokenStorage;

  /// Submit No HP + ID BAST → backend generate & kirim OTP via WhatsApp.
  Future<LoginOtpRequest> requestOtp({
    required String noHp,
    required String idBast,
  }) async {
    final res = await _api.post<LoginOtpRequest>(
      '/auth/login',
      data: {'hp': noHp, 'id_bast': idBast},
      fromData: (json) => LoginOtpRequest.fromJson(json as Map<String, dynamic>),
    );
    return res.data!;
  }

  /// Verifikasi kode OTP 4 digit → terbitkan & simpan Sanctum token.
  Future<void> verifyOtp({required String uid, required String otp}) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/auth/verify-otp',
      data: {'uid': uid, 'otp': otp},
      fromData: (json) => json as Map<String, dynamic>,
    );
    final token = res.data?['token']?.toString();
    if (token == null || token.isEmpty) {
      throw StateError('Token tidak ditemukan pada respons verify-otp.');
    }
    await _tokenStorage.saveToken(token);
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
    }
  }
}
