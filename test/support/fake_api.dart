import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:owner_easton_mobile/core/network/api_client.dart';
import 'package:owner_easton_mobile/core/storage/secure_token_storage.dart';

/// Respons palsu satu rute: status + body (JSON atau bytes mentah).
class RespPalsu {
  RespPalsu.json(this.status, Object? body)
      : bytes = Uint8List.fromList(utf8.encode(jsonEncode(body))),
        contentType = 'application/json';
  RespPalsu.bytes(this.bytes, {this.status = 200, this.contentType = 'application/octet-stream'});

  final int status;
  final Uint8List bytes;
  final String contentType;
}

Map<String, dynamic> amplop(Object? data, [String message = 'OK']) =>
    {'status': true, 'data': data, 'message': message, 'errors': null};

/// Adapter HTTP palsu berdasarkan "METHOD /path". Mencatat semua request.
class AdapterPalsu implements HttpClientAdapter {
  AdapterPalsu(this.rute);

  final Map<String, RespPalsu> rute;
  final List<RequestOptions> permintaan = [];

  RequestOptions? terakhir(String kunci) {
    for (final r in permintaan.reversed) {
      if ('${r.method} ${r.path}' == kunci) return r;
    }
    return null;
  }

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    permintaan.add(options);
    final r = rute['${options.method} ${options.path}'];
    if (r == null) {
      return ResponseBody.fromString(
        jsonEncode({'message': 'Tidak ada rute palsu untuk ${options.method} ${options.path}'}),
        500,
        headers: {Headers.contentTypeHeader: ['application/json']},
      );
    }
    return ResponseBody.fromBytes(r.bytes, r.status, headers: {
      Headers.contentTypeHeader: [r.contentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

(ApiClient, AdapterPalsu) apiPalsu(Map<String, RespPalsu> rute) {
  dotenv.testLoad(fileInput: 'API_BASE_URL=http://localhost/api/v1');
  FlutterSecureStorage.setMockInitialValues({});
  final adapter = AdapterPalsu(rute);
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))..httpClientAdapter = adapter;
  return (ApiClient(tokenStorage: SecureTokenStorage(), dio: dio), adapter);
}

/// PNG 1x1 valid.
final Uint8List pngKecil = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGP4z8AAAAMBAQDJ/pLvAAAAAElFTkSuQmCC',
);

final Uint8List pdfKecil = Uint8List.fromList(utf8.encode('%PDF-1.4\n%fake\n'));
