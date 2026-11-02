import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../env/env.dart';
import '../storage/secure_token_storage.dart';
import 'api_envelope.dart';

/// Klien HTTP tunggal untuk semua panggilan ke Laravel API (`/api/v1/...`).
///
/// - Menyisipkan header `Authorization: Bearer <token>` otomatis dari secure
///   storage (lihat docs/96 §3, alur Sanctum).
/// - Menerjemahkan setiap error non-2xx menjadi [ApiException] terstruktur
///   (status/message/errors) supaya UI tidak perlu parsing DioException manual.
/// - Backend memaksa semua path `api/*` selalu balas JSON terlepas header
///   Accept klien (lihat docs/96, update 19 Agustus — fix shouldRenderJsonWhen),
///   jadi kita tidak perlu header Accept khusus untuk itu, tapi tetap
///   dikirim untuk kejelasan.
class ApiClient {
  ApiClient({SecureTokenStorage? tokenStorage, Dio? dio})
      : _tokenStorage = tokenStorage ?? SecureTokenStorage(),
        _dio = dio ??
            Dio(BaseOptions(
              baseUrl: Env.apiBaseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
              headers: const {'Accept': 'application/json'},
            )) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final Dio _dio;
  final SecureTokenStorage _tokenStorage;

  Future<ApiEnvelope<T>> get<T>(
    String path, {
    Map<String, dynamic>? query,
    T Function(dynamic json)? fromData,
  }) =>
      _request(() => _dio.get(path, queryParameters: query), fromData);

  Future<ApiEnvelope<T>> post<T>(
    String path, {
    Object? data,
    T Function(dynamic json)? fromData,
  }) =>
      _request(() => _dio.post(path, data: data), fromData);

  Future<ApiEnvelope<T>> put<T>(
    String path, {
    Object? data,
    T Function(dynamic json)? fromData,
  }) =>
      _request(() => _dio.put(path, data: data), fromData);

  Future<ApiEnvelope<T>> delete<T>(
    String path, {
    Object? data,
    T Function(dynamic json)? fromData,
  }) =>
      _request(() => _dio.delete(path, data: data), fromData);

  /// Upload multipart (KTP/KK/foto profil/lampiran tiket) — lihat docs/96,
  /// endpoint `POST /profil/berkas` dan `POST /tiket/{id}/berkas`.
  Future<ApiEnvelope<T>> uploadMultipart<T>(
    String path, {
    required Map<String, dynamic> fields,
    required String filePath,
    required String fileFieldName,
    T Function(dynamic json)? fromData,
  }) =>
      _request(() async {
        final formData = FormData.fromMap({
          ...fields,
          fileFieldName: await MultipartFile.fromFile(filePath),
        });
        return _dio.post(path, data: formData);
      }, fromData);

  /// Unduh berkas biner (banner/dokumen yang butuh header Authorization sehingga tidak bisa
  /// lewat `Image.network`/URL langsung). Galat non-2xx dibaca dari body JSON (envelope atau
  /// `{"message": ...}` bawaan Laravel) menjadi [ApiException].
  Future<Uint8List> getBytes(String path, {Map<String, dynamic>? query}) async {
    try {
      final response = await _dio.get<List<int>>(
        path,
        queryParameters: query,
        options: Options(responseType: ResponseType.bytes),
      );
      return Uint8List.fromList(response.data ?? const <int>[]);
    } on DioException catch (e) {
      final raw = e.response?.data;
      String? pesan;
      Map<String, dynamic>? errors;
      if (raw is List<int> && raw.isNotEmpty) {
        try {
          final body = jsonDecode(utf8.decode(raw, allowMalformed: true));
          if (body is Map<String, dynamic>) {
            pesan = body['message']?.toString();
            errors = (body['errors'] as Map?)?.cast<String, dynamic>();
          }
        } on FormatException {
          // body bukan JSON (mis. HTML dari proxy) — pakai pesan bawaan.
        }
      }
      throw ApiException(
        statusCode: e.response?.statusCode,
        message: (pesan != null && pesan.isNotEmpty) ? pesan : (e.message ?? 'Tidak bisa terhubung ke server.'),
        errors: errors,
      );
    }
  }

  Future<ApiEnvelope<T>> _request<T>(
    Future<Response> Function() call,
    T Function(dynamic json)? fromData,
  ) async {
    try {
      final response = await call();
      final json = response.data as Map<String, dynamic>;
      return ApiEnvelope<T>.fromJson(json, fromData);
    } on DioException catch (e) {
      final body = e.response?.data;
      if (body is Map<String, dynamic>) {
        throw ApiException(
          statusCode: e.response?.statusCode,
          message: body['message']?.toString() ?? 'Terjadi kesalahan.',
          errors: (body['errors'] as Map?)?.cast<String, dynamic>(),
        );
      }
      throw ApiException(
        statusCode: e.response?.statusCode,
        message: e.message ?? 'Tidak bisa terhubung ke server.',
      );
    }
  }
}
