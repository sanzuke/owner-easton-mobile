import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app_router.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/tampilan.dart';
import 'features/dashboard/application/tampilan_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await initializeDateFormatting('id_ID');
  // Firebase (push notification, Tier 1) diinisialisasi di sini setelah
  // project Firebase disediakan dan file konfigurasi platform (
  // google-services.json / GoogleService-Info.plist) ditambahkan — lihat
  // docs/96_perencanaan_mobile_app_owner.md §3 & §8 (belum diputuskan akun
  // organisasi mana). Placeholder sengaja belum memanggil Firebase.initializeApp()
  // supaya build tidak gagal sebelum config platform tersedia.
  runApp(const ProviderScope(child: OwnerEastonApp()));
}

class OwnerEastonApp extends ConsumerWidget {
  const OwnerEastonApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = ref.watch(temaPilihanProvider).valueOrNull ?? TemaPilihan.sistem;
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: tema.mode,
      // Dibutuhkan widget bawaan Material (mis. date range picker) agar bisa tampil berbahasa Indonesia.
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('id'), Locale('en')],
      routerConfig: appRouter,
    );
  }
}
