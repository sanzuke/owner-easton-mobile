import 'package:firebase_messaging/firebase_messaging.dart';

/// Pesan push yang disederhanakan (lepas dari tipe firebase_messaging supaya
/// [PushService] bisa diuji tanpa Firebase).
class PushMessage {
  const PushMessage({this.title, this.body, this.data = const {}});

  final String? title;
  final String? body;

  /// Payload data dari backend (docs/96b §11b): `id_notifikasi`, `tipe`, dan
  /// field kustom (mis. `id_billing`) — semua bertipe string.
  final Map<String, String> data;
}

/// Pintu ke FCM. Implementasi nyata: [FirebasePushBackend]; di tes diganti fake.
abstract class PushBackend {
  /// Minta izin notifikasi (Android 13+/iOS). `true` bila diizinkan.
  Future<bool> requestPermission();

  Future<String?> getToken();

  Stream<String> get onTokenRefresh;

  /// Pesan masuk saat app terbuka (foreground).
  Stream<PushMessage> get onForegroundMessage;

  /// Notifikasi diketuk saat app di background.
  Stream<PushMessage> get onOpenedFromBackground;

  /// Notifikasi yang membuka app dari keadaan tertutup (sekali pakai).
  Future<PushMessage?> getInitialMessage();

  Future<void> deleteToken();
}

class FirebasePushBackend implements PushBackend {
  FirebasePushBackend([FirebaseMessaging? messaging]) : _fm = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _fm;

  static PushMessage _map(RemoteMessage m) => PushMessage(
        title: m.notification?.title,
        body: m.notification?.body,
        data: m.data.map((k, v) => MapEntry(k, v?.toString() ?? '')),
      );

  @override
  Future<bool> requestPermission() async {
    final s = await _fm.requestPermission();
    return s.authorizationStatus == AuthorizationStatus.authorized ||
        s.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Future<String?> getToken() => _fm.getToken();

  @override
  Stream<String> get onTokenRefresh => _fm.onTokenRefresh;

  @override
  Stream<PushMessage> get onForegroundMessage => FirebaseMessaging.onMessage.map(_map);

  @override
  Stream<PushMessage> get onOpenedFromBackground => FirebaseMessaging.onMessageOpenedApp.map(_map);

  @override
  Future<PushMessage?> getInitialMessage() async {
    final m = await _fm.getInitialMessage();
    return m == null ? null : _map(m);
  }

  @override
  Future<void> deleteToken() => _fm.deleteToken();
}
