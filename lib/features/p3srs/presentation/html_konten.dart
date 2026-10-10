import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:url_launcher/url_launcher.dart';

/// Situs utama tempat gambar relatif di isi artikel CMS berada.
final Uri _situsUtama = Uri.parse('https://eprjatinangor.com/');

/// Render HTML dari CMS/laporan admin. Tautan dibuka di aplikasi luar; gambar relatif mengacu ke situs utama.
/// Tabel diberi garis tipis karena CSS asli (Bootstrap/Argon) tidak ikut terbawa ke app.
class HtmlKonten extends StatelessWidget {
  const HtmlKonten(this.html, {super.key});

  final String html;

  @override
  Widget build(BuildContext context) {
    final garis = Theme.of(context).colorScheme.outlineVariant;
    String warna(Color c) =>
        '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

    return HtmlWidget(
      html,
      baseUrl: _situsUtama,
      onTapUrl: (url) async {
        final uri = Uri.tryParse(url);
        if (uri == null) return false;
        return launchUrl(uri, mode: LaunchMode.externalApplication);
      },
      customStylesBuilder: (e) {
        switch (e.localName) {
          case 'table':
            return {'border': '1px solid ${warna(garis)}', 'border-collapse': 'collapse'};
          case 'td':
          case 'th':
            return {'border': '1px solid ${warna(garis)}', 'padding': '4px 6px'};
        }
        return null;
      },
    );
  }
}
