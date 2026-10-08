import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app_router.dart';
import 'app/navigator_keys.dart';
import 'core/constants/app_constants.dart';
import 'core/push/push_providers.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await initializeDateFormatting('id_ID');
  // Firebase untuk push notification. Bila config platform (google-services.json /
  // GoogleService-Info.plist) belum dipasang, inisialisasi gagal: push dimatikan tetapi
  // aplikasi tetap berjalan.
  var firebaseSiap = false;
  try {
    await Firebase.initializeApp();
    firebaseSiap = true;
  } catch (e) {
    debugPrint('Firebase tidak aktif, push dimatikan: $e');
  }
  runApp(ProviderScope(
    overrides: [firebaseSiapProvider.overrideWith((ref) => firebaseSiap)],
    child: const OwnerEastonApp(),
  ));
}

class OwnerEastonApp extends StatelessWidget {
  const OwnerEastonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      scaffoldMessengerKey: scaffoldMessengerKey,
      routerConfig: appRouter,
    );
  }
}
