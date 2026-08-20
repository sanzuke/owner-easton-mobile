/// Bungkus response envelope standar backend Laravel:
/// `{ "status": bool, "data": ..., "message": string, "errors": {...} }`
/// (lihat docs/96_perencanaan_mobile_app_owner.md §3).
class ApiEnvelope<T> {
  final bool status;
  final T? data;
  final String message;
  final Map<String, dynamic>? errors;

  const ApiEnvelope({
    required this.status,
    required this.data,
    required this.message,
    this.errors,
  });

  factory ApiEnvelope.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json)? fromData,
  ) {
    final rawData = json['data'];
    return ApiEnvelope<T>(
      status: json['status'] == true,
      data: fromData != null && rawData != null ? fromData(rawData) : rawData as T?,
      message: json['message']?.toString() ?? '',
      errors: (json['errors'] as Map?)?.cast<String, dynamic>(),
    );
  }
}

/// Exception terstruktur untuk error API (4xx/5xx) — dipakai UI untuk
/// menampilkan pesan/errors per-field (mis. validasi 422).
class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final Map<String, dynamic>? errors;

  const ApiException({required this.message, this.statusCode, this.errors});

  @override
  String toString() => 'ApiException($statusCode): $message';
}
