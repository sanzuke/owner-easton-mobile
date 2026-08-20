import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Wrapper baca konfigurasi environment dari .env (lihat .env.example).
///
/// Load sekali di main.dart sebelum runApp() via `await dotenv.load()`.
class Env {
  Env._();

  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000/api/v1';
}
