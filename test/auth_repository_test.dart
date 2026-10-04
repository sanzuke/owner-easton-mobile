import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:owner_easton_mobile/core/network/api_client.dart';
import 'package:owner_easton_mobile/core/network/api_envelope.dart';
import 'package:owner_easton_mobile/core/storage/secure_token_storage.dart';
import 'package:owner_easton_mobile/features/auth/data/auth_repository.dart';

/// Adapter HTTP palsu: mengembalikan respons JSON yang sudah ditentukan per path
/// dan mencatat body request terakhir.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.responses);

  final Map<String, (int, Map<String, dynamic>)> responses;
  final Map<String, Object?> lastBody = {};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastBody[options.path] = options.data;
    final (status, body) = responses[options.path]!;
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

(AuthRepository, SecureTokenStorage, _FakeAdapter) _repo(
  Map<String, (int, Map<String, dynamic>)> responses,
) {
  FlutterSecureStorage.setMockInitialValues({});
  final storage = SecureTokenStorage();
  final adapter = _FakeAdapter(responses);
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))..httpClientAdapter = adapter;
  final repo = AuthRepository(
    apiClient: ApiClient(tokenStorage: storage, dio: dio),
    tokenStorage: storage,
  );
  return (repo, storage, adapter);
}

Map<String, dynamic> _ok(Map<String, dynamic>? data, [String message = 'ok']) =>
    {'status': true, 'data': data, 'message': message, 'errors': null};

void main() {
  setUpAll(() => dotenv.testLoad(fileInput: 'API_BASE_URL=http://localhost/api/v1'));

  test('login sukses menyimpan token; password default menandai wajib-ganti', () async {
    final (repo, storage, adapter) = _repo({
      '/auth/login': (200, _ok({'token': '1|abc', 'must_change_password': true})),
    });

    final result = await repo.login(noHp: '0812', idBast: '7', password: 'rahasia');

    expect(result.mustChangePassword, isTrue);
    expect(await storage.readToken(), '1|abc');
    expect(await storage.isPasswordChangePending(), isTrue);
    expect(adapter.lastBody['/auth/login'], {'hp': '0812', 'id_bast': '7', 'password': 'rahasia'});
  });

  test('login dengan password sendiri tidak memasang penanda wajib-ganti', () async {
    final (repo, storage, _) = _repo({
      '/auth/login': (200, _ok({'token': '1|abc', 'must_change_password': false})),
    });

    final result = await repo.login(noHp: '0812', idBast: '7', password: 'rahasia');

    expect(result.mustChangePassword, isFalse);
    expect(await storage.isPasswordChangePending(), isFalse);
  });

  test('login gagal melempar ApiException berisi pesan server dan tidak menyimpan token', () async {
    final (repo, storage, _) = _repo({
      '/auth/login': (
        401,
        {'status': false, 'data': null, 'message': 'Password salah. Percobaan ke-1 dari 5', 'errors': null},
      ),
    });

    await expectLater(
      repo.login(noHp: '0812', idBast: '7', password: 'x'),
      throwsA(isA<ApiException>()
          .having((e) => e.statusCode, 'statusCode', 401)
          .having((e) => e.message, 'message', contains('Percobaan ke-1'))),
    );
    expect(await storage.readToken(), isNull);
  });

  test('ganti password wajib-ganti tidak mengirim password lama dan mencabut penanda', () async {
    final (repo, storage, adapter) = _repo({
      '/auth/ganti-password': (200, _ok(null, 'Password berhasil diubah.')),
    });
    await storage.setPasswordChangePending(true);

    await repo.changePassword(newPassword: 'BaruBanget-1', confirmPassword: 'BaruBanget-1');

    expect(adapter.lastBody['/auth/ganti-password'], {
      'new_password': 'BaruBanget-1',
      'confirm_password': 'BaruBanget-1',
    });
    expect(await storage.isPasswordChangePending(), isFalse);
  });

  test('ganti password gagal tidak mencabut penanda wajib-ganti', () async {
    final (repo, storage, _) = _repo({
      '/auth/ganti-password': (
        422,
        {'status': false, 'data': null, 'message': 'Password baru minimal 8 karakter.', 'errors': null},
      ),
    });
    await storage.setPasswordChangePending(true);

    await expectLater(
      repo.changePassword(newPassword: 'pendek', confirmPassword: 'pendek'),
      throwsA(isA<ApiException>()),
    );
    expect(await storage.isPasswordChangePending(), isTrue);
  });

  test('logout membersihkan token, biometrik, dan penanda wajib-ganti', () async {
    final (repo, storage, _) = _repo({'/auth/logout': (200, _ok(null))});
    await storage.saveToken('t');
    await storage.setBiometricEnabled(true);
    await storage.setPasswordChangePending(true);

    await repo.logout();

    expect(await storage.readToken(), isNull);
    expect(await storage.isBiometricEnabled(), isFalse);
    expect(await storage.isPasswordChangePending(), isFalse);
  });
}
