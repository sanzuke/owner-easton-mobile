import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Versi terpasang: `version` = nama versi dari `pubspec.yaml`, `buildNumber` = android versionCode / iOS CFBundleVersion
/// (naik otomatis oleh `scripts/build.*`).
final appInfoProvider = FutureProvider<PackageInfo>((ref) => PackageInfo.fromPlatform());

/// Teks tampilan, mis. "1.1.0 (build 12345)".
String labelVersi(PackageInfo info) => '${info.version} (build ${info.buildNumber})';
