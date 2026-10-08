import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:owner_easton_mobile/core/network/api_client.dart';
import 'package:owner_easton_mobile/core/push/push_backend.dart';
import 'package:owner_easton_mobile/core/push/push_service.dart';
import 'package:owner_easton_mobile/core/storage/secure_token_storage.dart';
import 'package:owner_easton_mobile/features/auth/data/auth_repository.dart';
import 'package:owner_easton_mobile/features/notifikasi/data/notifikasi_repository.dart';

/// Mencatat tiap request ("METHOD path") berikut body-nya; status 500 bila [gagal].
class _Adapter implements HttpClientAdapter {
  final List<String> log = [];
  final List<Object?> bodies = [];
  bool gagal = false;

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? s, Future<void>? c) async {
    log.add('${o.method} ${o.path}');
    bodies.add(o.data);
    return ResponseBody.fromString(
      jsonEncode({'status': !gagal, 'data': null, 'message': gagal ? 'boom' : 'ok', 'errors': null}),
      gagal ? 500 : 200,
      headers: {Headers.contentTypeHeader: ['application/json']},
    );
  }

  @override
  void close({bool force = false}) {}
}

class _FakeBackend implements PushBackend {
  bool izin = true;
  String? token = 'tok-1';
  PushMessage? awal;
  bool tokenDihapus = false;
  final refresh = StreamController<String>.broadcast();
  final foreground = StreamController<PushMessage>.broadcast();
  final dibuka = StreamController<PushMessage>.broadcast();

  @override
  Future<bool> requestPermission() async => izin;
  @override
  Future<String?> getToken() async => token;
  @override
  Stream<String> get onTokenRefresh => refresh.stream;
  @override
  Stream<PushMessage> get onForegroundMessage => foreground.stream;
  @override
  Stream<PushMessage> get onOpenedFromBackground => dibuka.stream;
  @override
  Future<PushMessage?> getInitialMessage() async => awal;
  @override
  Future<void> deleteToken() async => tokenDihapus = true;
}

(PushService, _FakeBackend, _Adapter, SecureTokenStorage) _siap({String? Function()? platform}) {
  FlutterSecureStorage.setMockInitialValues({});
  final storage = SecureTokenStorage();
  final adapter = _Adapter();
  final api = ApiClient(
    tokenStorage: storage,
    dio: Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))..httpClientAdapter = adapter,
  );
  final backend = _FakeBackend();
  final service = PushService(
    backend: backend,
    repository: NotifikasiRepository(apiClient: api),
    platform: platform ?? () => 'android',
    appVersion: '1.2.3',
  );
  return (service, backend, adapter, storage);
}

Future<void> _tunggu() => Future<void>.delayed(const Duration(milliseconds: 50));

void main() {
  setUpAll(() => dotenv.testLoad(fileInput: 'API_BASE_URL=http://localhost/api/v1'));

  test('mulai mendaftarkan token FCM dengan platform dan versi app', () async {
    final (service, _, adapter, _) = _siap();

    await service.mulai();

    expect(adapter.log, ['POST /device-token']);
    expect(adapter.bodies.single, {'token': 'tok-1', 'platform': 'android', 'app_version': '1.2.3'});
    expect(service.tokenTerdaftar, 'tok-1');
  });

  test('izin ditolak: tidak ada pendaftaran dan tidak mendengarkan apa pun', () async {
    final (service, backend, adapter, _) = _siap();
    backend.izin = false;

    await service.mulai();
    backend.refresh.add('tok-2');
    await _tunggu();

    expect(adapter.log, isEmpty);
    expect(service.tokenTerdaftar, isNull);
  });

  test('platform tanpa FCM (desktop) tidak melakukan apa pun', () async {
    final (service, _, adapter, _) = _siap(platform: () => null);

    await service.mulai();

    expect(adapter.log, isEmpty);
  });

  test('token yang diperbarui FCM didaftarkan ulang; mulai dua kali tidak menggandakan', () async {
    final (service, backend, adapter, _) = _siap();

    await service.mulai();
    await service.mulai();
    backend.refresh.add('tok-2');
    await _tunggu();

    expect(adapter.log, ['POST /device-token', 'POST /device-token']);
    expect((adapter.bodies.last as Map)['token'], 'tok-2');
    expect(service.tokenTerdaftar, 'tok-2');
  });

  test('pesan foreground, ketukan dari background, dan pembuka dari keadaan tertutup diteruskan', () async {
    final (service, backend, _, _) = _siap();
    final fg = <PushMessage>[];
    final buka = <PushMessage>[];
    service
      ..onForeground = fg.add
      ..onDibuka = buka.add;
    backend.awal = const PushMessage(title: 'Dari tertutup');

    await service.mulai();
    backend.foreground.add(const PushMessage(title: 'Tagihan terbit', data: {'id_billing': '9'}));
    backend.dibuka.add(const PushMessage(title: 'Diketuk'));
    await _tunggu();

    expect(fg.single.title, 'Tagihan terbit');
    expect(fg.single.data['id_billing'], '9');
    expect(buka.map((m) => m.title), ['Dari tertutup', 'Diketuk']);
  });

  test('gagal mendaftar (server 500) tidak melempar dan token tidak dianggap terdaftar', () async {
    final (service, _, adapter, _) = _siap();
    adapter.gagal = true;

    await service.mulai();

    expect(adapter.log, ['POST /device-token']);
    expect(service.tokenTerdaftar, isNull);
  });

  test('berhenti melepas token di server, menghapus token FCM lokal, dan berhenti mendengarkan', () async {
    final (service, backend, adapter, _) = _siap();
    final fg = <PushMessage>[];
    service.onForeground = fg.add;
    await service.mulai();
    adapter.log.clear();
    adapter.bodies.clear();

    await service.berhenti();
    backend.foreground.add(const PushMessage(title: 'setelah logout'));
    backend.refresh.add('tok-3');
    await _tunggu();

    expect(adapter.log, ['DELETE /device-token']);
    expect(adapter.bodies.single, {'token': 'tok-1'});
    expect(backend.tokenDihapus, isTrue);
    expect(fg, isEmpty);
    expect(service.tokenTerdaftar, isNull);

    // login berikutnya (akun lain) bisa mulai lagi dari awal
    await service.mulai();
    expect(adapter.log.last, 'POST /device-token');
  });

  test('berhenti tanpa token terdaftar tidak memanggil server', () async {
    final (service, backend, adapter, _) = _siap();

    await service.berhenti();

    expect(adapter.log, isEmpty);
    expect(backend.tokenDihapus, isTrue);
  });

  test('logout menjalankan sebelumLogout selagi token login masih ada, dan tetap logout bila hook gagal', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final storage = SecureTokenStorage();
    await storage.saveToken('1|abc');
    final adapter = _Adapter();
    final api = ApiClient(
      tokenStorage: storage,
      dio: Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))..httpClientAdapter = adapter,
    );
    String? tokenSaatHook;
    final repo = AuthRepository(
      apiClient: api,
      tokenStorage: storage,
      sebelumLogout: () async {
        tokenSaatHook = await storage.readToken();
        adapter.log.add('HOOK');
        throw Exception('gagal');
      },
    );

    await repo.logout();

    expect(tokenSaatHook, '1|abc');
    expect(adapter.log, ['HOOK', 'POST /auth/logout']);
    expect(await storage.readToken(), isNull);
  });
}
