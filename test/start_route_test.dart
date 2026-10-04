import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:owner_easton_mobile/core/auth/biometric_service.dart';
import 'package:owner_easton_mobile/core/providers/core_providers.dart';
import 'package:owner_easton_mobile/core/storage/secure_token_storage.dart';
import 'package:owner_easton_mobile/features/auth/application/biometric_providers.dart';

class _FakeBiometric extends BiometricService {
  _FakeBiometric(this.available);
  final bool available;

  @override
  Future<bool> isAvailable() async => available;
}

Future<(String, SecureTokenStorage)> _route({
  String? token,
  bool biometricEnabled = false,
  bool available = true,
  bool passwordChangePending = false,
}) async {
  FlutterSecureStorage.setMockInitialValues({
    'sanctum_token': ?token,
    if (biometricEnabled) 'biometric_enabled': 'true',
    if (passwordChangePending) 'password_change_pending': 'true',
  });
  final storage = SecureTokenStorage();
  final container = ProviderContainer(overrides: [
    secureTokenStorageProvider.overrideWithValue(storage),
    biometricServiceProvider.overrideWithValue(_FakeBiometric(available)),
  ]);
  addTearDown(container.dispose);
  return (await container.read(startRouteProvider.future), storage);
}

void main() {
  setUpAll(() => dotenv.testLoad(fileInput: 'API_BASE_URL=http://localhost/api/v1'));

  test('belum login -> /login', () async {
    expect((await _route()).$1, '/login');
  });

  test('login tanpa buka cepat -> /dashboard', () async {
    expect((await _route(token: 't')).$1, '/dashboard');
  });

  test('login + buka cepat aktif + biometrik tersedia -> /unlock', () async {
    expect((await _route(token: 't', biometricEnabled: true)).$1, '/unlock');
  });

  test('buka cepat aktif tapi biometrik hilang -> /login dan sesi lokal dihapus (fail-closed)', () async {
    final (route, storage) = await _route(token: 't', biometricEnabled: true, available: false);
    expect(route, '/login');
    expect(await storage.readToken(), isNull);
    expect(await storage.isBiometricEnabled(), isFalse);
  });

  test('flag biometrik tanpa token tidak membuka gerbang', () async {
    expect((await _route(biometricEnabled: true)).$1, '/login');
  });

  test('wajib ganti password default -> /ganti-password, mendahului gerbang biometrik', () async {
    expect((await _route(token: 't', passwordChangePending: true)).$1, '/ganti-password');
    expect(
      (await _route(token: 't', passwordChangePending: true, biometricEnabled: true)).$1,
      '/ganti-password',
    );
  });

  test('penanda ganti password tanpa token tetap /login', () async {
    expect((await _route(passwordChangePending: true)).$1, '/login');
  });
}
