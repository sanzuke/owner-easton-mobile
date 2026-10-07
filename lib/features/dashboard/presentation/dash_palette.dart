import 'package:flutter/material.dart';

import '../../../core/theme/tampilan.dart';

/// Palet dashboard — nilai diambil dari prototipe desain (variabel CSS `--primary`, `--ink`, dst.).
/// Nyaman mengikuti mode terang/gelap perangkat; Modern selalu gelap.
class DashPalette {
  const DashPalette({
    required this.modern,
    required this.bg,
    required this.surface,
    required this.surfaceTonal,
    required this.primary,
    required this.primaryDark,
    required this.primaryTint,
    required this.ink,
    required this.inkSoft,
    required this.inkFaint,
    required this.pay,
    required this.warnBg,
    required this.warnText,
    required this.okBg,
    required this.okText,
    required this.border,
    required this.headerStart,
    required this.headerEnd,
    required this.onHeader,
    required this.onHeaderSoft,
  });

  final bool modern;
  final Color bg, surface, surfaceTonal, primary, primaryDark, primaryTint;
  final Color ink, inkSoft, inkFaint, pay, warnBg, warnText, okBg, okText, border;
  final Color headerStart, headerEnd, onHeader, onHeaderSoft;

  static const nyamanTerang = DashPalette(
    modern: false,
    bg: Color(0xFFF1F1EE),
    surface: Color(0xFFFFFFFF),
    surfaceTonal: Color(0xFFF4F0DC),
    primary: Color(0xFFAC9A2E),
    primaryDark: Color(0xFF857524),
    primaryTint: Color(0xFFF2EDD3),
    ink: Color(0xFF232A3B),
    inkSoft: Color(0xFF5B6478),
    inkFaint: Color(0xFF8991A3),
    pay: Color(0xFFC94B44),
    warnBg: Color(0xFFFBE4E2),
    warnText: Color(0xFFA13934),
    okBg: Color(0xFFE3EFE1),
    okText: Color(0xFF2F6B3A),
    border: Color(0xFFE1E1DA),
    headerStart: Color(0xFFAC9A2E),
    headerEnd: Color(0xFF857524),
    onHeader: Color(0xFF232A3B),
    onHeaderSoft: Color(0x8C232A3B),
  );

  static const nyamanGelap = DashPalette(
    modern: false,
    bg: Color(0xFF14171F),
    surface: Color(0xFF1D2130),
    surfaceTonal: Color(0xFF2A2A1C),
    primary: Color(0xFFD8C450),
    primaryDark: Color(0xFFB7A43D),
    primaryTint: Color(0xFF333120),
    ink: Color(0xFFECEEF3),
    inkSoft: Color(0xFFABB2C4),
    inkFaint: Color(0xFF7A8194),
    pay: Color(0xFFE17870),
    warnBg: Color(0xFF3A2420),
    warnText: Color(0xFFEC9A93),
    okBg: Color(0xFF1F2E20),
    okText: Color(0xFF8FCB98),
    border: Color(0xFF333A4C),
    headerStart: Color(0xFFD8C450),
    headerEnd: Color(0xFFB7A43D),
    onHeader: Color(0xFF232A3B),
    onHeaderSoft: Color(0x8C232A3B),
  );

  static const modernGelap = DashPalette(
    modern: true,
    bg: Color(0xFF191C26),
    surface: Color(0xFF21242F),
    surfaceTonal: Color(0xFF2E2A16),
    primary: Color(0xFFE3CB55),
    primaryDark: Color(0xFF2B2508),
    primaryTint: Color(0xFF33301C),
    ink: Color(0xFFFFFFFF),
    inkSoft: Color(0xFFA3A8BC),
    inkFaint: Color(0xFFA3A8BC),
    pay: Color(0xFFE17870),
    warnBg: Color(0xFF3A2724),
    warnText: Color(0xFFE17870),
    okBg: Color(0xFF38341C),
    okText: Color(0xFFE3CB55),
    border: Color(0xFF343849),
    headerStart: Color(0xFF2B2610),
    headerEnd: Color(0xFF191C26),
    onHeader: Color(0xFFFFFFFF),
    onHeaderSoft: Color(0xFFA3A8BC),
  );

  static DashPalette untuk(TampilanMode mode, Brightness kecerahan) {
    if (mode == TampilanMode.modern) return modernGelap;
    return kecerahan == Brightness.dark ? nyamanGelap : nyamanTerang;
  }
}
