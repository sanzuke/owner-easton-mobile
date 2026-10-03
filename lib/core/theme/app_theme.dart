import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tema aplikasi — Material 3, gaya datar & tenang: AppBar menyatu dengan
/// latar, kartu tanpa bayangan dengan garis tipis, input berisi lembut,
/// tombol pil. Semua komponen membaca ColorScheme sehingga mode terang dan
/// gelap konsisten (tidak ada warna hardcode di layar).
class AppTheme {
  AppTheme._();

  static const _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primaryOlive,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFE4EAD6),
    onPrimaryContainer: Color(0xFF1D2810),
    secondary: AppColors.navyAccent,
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFE3E6EE),
    onSecondaryContainer: Color(0xFF1B2232),
    error: AppColors.destructive,
    onError: Colors.white,
    surface: Colors.white,
    onSurface: Color(0xFF1D1D18),
    onSurfaceVariant: Color(0xFF6A6A60),
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: Color(0xFFF7F6F2),
    surfaceContainer: Color(0xFFF1F0EA),
    surfaceContainerHigh: Color(0xFFEBEAE3),
    surfaceContainerHighest: Color(0xFFE5E4DC),
    outline: Color(0xFFB9B8AE),
    outlineVariant: Color(0xFFE8E6DE),
  );

  static const _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFB4C58A),
    onPrimary: Color(0xFF1F2B0E),
    primaryContainer: Color(0xFF38472A),
    onPrimaryContainer: Color(0xFFD6E6AB),
    secondary: Color(0xFFB7C1D9),
    onSecondary: Color(0xFF1F2A40),
    secondaryContainer: Color(0xFF353F55),
    onSecondaryContainer: Color(0xFFDCE2F3),
    error: Color(0xFFFF8A80),
    onError: Color(0xFF410002),
    surface: Color(0xFF1A1B17),
    onSurface: Color(0xFFE7E6DD),
    onSurfaceVariant: Color(0xFFA9A99D),
    surfaceContainerLowest: Color(0xFF0F100D),
    surfaceContainerLow: Color(0xFF141510),
    surfaceContainer: Color(0xFF1F201B),
    surfaceContainerHigh: Color(0xFF292A24),
    surfaceContainerHighest: Color(0xFF33342D),
    outline: Color(0xFF6F7066),
    outlineVariant: Color(0xFF2E2F28),
  );

  static ThemeData light() => _build(_lightScheme, AppColors.background);

  static ThemeData dark() => _build(_darkScheme, const Color(0xFF11120F));

  static ThemeData _build(ColorScheme cs, Color scaffold) {
    final isDark = cs.brightness == Brightness.dark;
    final base = ThemeData(brightness: cs.brightness, useMaterial3: true);
    final textTheme = base.textTheme
        .apply(bodyColor: cs.onSurface, displayColor: cs.onSurface)
        .copyWith(
          titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
          titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        );

    OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: cs.brightness,
      colorScheme: cs,
      scaffoldBackgroundColor: scaffold,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        foregroundColor: cs.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: cs.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 68,
        indicatorColor: cs.primaryContainer,
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? cs.onSurface : cs.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? cs.onPrimaryContainer : cs.onSurfaceVariant);
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? cs.surfaceContainer : cs.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.8)),
        border: border(cs.outlineVariant),
        enabledBorder: border(cs.outlineVariant),
        focusedBorder: border(cs.primary, 1.6),
        errorBorder: border(cs.error),
        focusedErrorBorder: border(cs.error, 1.6),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: cs.primary),
      ),
      cardTheme: CardThemeData(
        color: cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: cs.outlineVariant),
        ),
      ),
      dividerTheme: DividerThemeData(color: cs.outlineVariant, space: 1, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}
