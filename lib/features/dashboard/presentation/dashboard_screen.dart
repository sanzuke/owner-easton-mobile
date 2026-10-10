import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/shell_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/tampilan.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/coming_soon_screen.dart';
import '../../acara/application/acara_providers.dart';
import '../../acara/presentation/acara_screen.dart';
import '../../notifikasi/application/notifikasi_providers.dart';
import '../../notifikasi/presentation/notifikasi_screen.dart';
import '../../p3srs/application/p3srs_providers.dart';
import '../../p3srs/presentation/berita_beranda.dart';
import '../../pembayaran/presentation/pembayaran_screen.dart';
import '../../tagihan/presentation/tagihan_detail_screen.dart';
import '../application/dashboard_providers.dart';
import '../application/tampilan_providers.dart';
import '../data/dashboard_repository.dart';
import 'dash_palette.dart';
import 'tampilan_screen.dart';

/// Beranda — mengikuti prototipe desain (Portal Pemilik): sapaan + unit, kartu tagihan bulan ini
/// dengan tombol bayar, dan 6 kartu fitur. Dua tema: Nyaman (besar, kontras tinggi; default usia
/// >= 55 tahun) dan Modern (ringkas, gelap). Pemilik bisa memilih sendiri di Pengaturan > Tampilan.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final mode = ref.watch(tampilanModeProvider);
    final p = DashPalette.untuk(mode, Theme.of(context).brightness);

    final terang = Theme.of(context).brightness == Brightness.light;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (p.modern && !terang) ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: ColoredBox(
        color: p.bg,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dashboardSummaryProvider);
            ref.invalidate(acaraListProvider);
            ref.invalidate(notifikasiBelumDibacaProvider);
            ref.invalidate(beritaTerbaruProvider);
          },
          child: summaryAsync.when(
            loading: () => ListView(children: [
              SizedBox(height: 160, child: Center(child: CircularProgressIndicator(color: p.primary))),
            ]),
            error: (err, _) => ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 96),
                Text('Gagal memuat beranda.\n$err',
                    textAlign: TextAlign.center, style: TextStyle(color: p.ink)),
                const SizedBox(height: 16),
                Center(
                  child: FilledButton(
                    onPressed: () => ref.invalidate(dashboardSummaryProvider),
                    child: const Text('Coba lagi'),
                  ),
                ),
              ],
            ),
            data: (s) => ListView(
              padding: EdgeInsets.zero,
              children: [
                _Header(summary: s, p: p),
                Padding(
                  padding: EdgeInsets.fromLTRB(p.modern ? 16 : 20, 14, p.modern ? 16 : 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _BillCard(summary: s, p: p),
                      _AcaraBanner(p: p),
                      const SizedBox(height: 14),
                      _SectionLabel(p: p),
                      const SizedBox(height: 10),
                      _FeatureGrid(summary: s, p: p),
                      BeritaBeranda(p: p),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.summary, required this.p});

  final DashboardSummary summary;
  final DashPalette p;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(sekarangProvider);
    final panggilan = namaPanggilan(summary.namaPemilik);
    final sapa = sebutan(summary.jenisKelamin);
    final nama = p.modern
        ? (panggilan.isEmpty ? 'Hi 👋' : 'Hi, $panggilan 👋')
        : (panggilan.isEmpty ? sapa : '$sapa $panggilan');
    final eyebrow = p.modern ? sapaanWaktu(now).toUpperCase() : sapaanWaktu(now);
    final unit = 'Unit ${summary.unitCode ?? '-'}'
        '${summary.tower != null && summary.tower!.isNotEmpty ? ' · Tower ${summary.tower}' : ''}';

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [p.headerStart, p.headerEnd],
          stops: p.modern ? const [0, 0.65] : null,
        ),
        borderRadius: p.modern ? null : const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Stack(
        children: [
          if (p.modern)
            Positioned(
              top: -40,
              right: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [p.primary.withValues(alpha: 0.35), Colors.transparent], stops: const [0, 0.7]),
                ),
              ),
            ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(p.modern ? 20 : 22, 18, p.modern ? 20 : 22, p.modern ? 22 : 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          eyebrow,
                          style: TextStyle(
                            color: p.onHeaderSoft,
                            fontSize: p.modern ? 12 : 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: p.modern ? 0.5 : 0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          nama,
                          style: TextStyle(
                            color: p.onHeader,
                            fontSize: p.modern ? 19 : 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.home_outlined, size: p.modern ? 14 : 16, color: p.modern ? p.primary : p.onHeader),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                unit,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: p.modern ? p.inkSoft : p.onHeader,
                                  fontSize: p.modern ? 12 : 13.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 7),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: p.modern ? 7 : 9, vertical: 2),
                              decoration: BoxDecoration(
                                color: p.modern ? p.primary.withValues(alpha: 0.2) : p.onHeader.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(p.modern ? 6 : 100),
                              ),
                              child: Text(
                                p.modern ? 'AKTIF' : 'Aktif',
                                style: TextStyle(
                                  color: p.modern ? p.primary : p.onHeader,
                                  fontSize: p.modern ? 10 : 11.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _Bell(p: p),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bell extends ConsumerWidget {
  const _Bell({required this.p});

  final DashPalette p;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final belumDibaca = ref.watch(notifikasiBelumDibacaProvider).valueOrNull ?? 0;
    final size = p.modern ? 40.0 : 46.0;
    return Semantics(
      button: true,
      label: belumDibaca > 0 ? 'Notifikasi, $belumDibaca belum dibaca' : 'Notifikasi',
      child: InkWell(
        borderRadius: BorderRadius.circular(p.modern ? 12 : 14),
        onTap: () async {
          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotifikasiScreen()));
          ref.invalidate(notifikasiBelumDibacaProvider);
        },
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: p.modern ? p.surface : p.onHeader.withValues(alpha: 0.14),
            border: p.modern ? Border.all(color: p.border) : null,
            borderRadius: BorderRadius.circular(p.modern ? 12 : 14),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.notifications_none_rounded, size: p.modern ? 19 : 22, color: p.modern ? p.inkSoft : p.onHeader),
              if (belumDibaca > 0)
                Positioned(
                  top: p.modern ? 7 : 9,
                  right: p.modern ? 8 : 10,
                  child: Container(
                    width: p.modern ? 8 : 9,
                    height: p.modern ? 8 : 9,
                    decoration: BoxDecoration(
                      color: p.pay,
                      shape: BoxShape.circle,
                      border: Border.all(color: p.modern ? p.surface : p.primary, width: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BillCard extends StatelessWidget {
  const _BillCard({required this.summary, required this.p});

  final DashboardSummary summary;
  final DashPalette p;

  @override
  Widget build(BuildContext context) {
    final t = summary.tagihanTerbaru;
    final lunas = t == null || t.lunas;
    final total = t?.total ?? 0;
    final lewat = t != null && !t.lunas && t.jatuhTempo != null && t.jatuhTempo!.isBefore(DateTime.now());
    final jt = t?.jatuhTempo;
    final due = t == null
        ? 'Belum ada tagihan'
        : t.lunas
            ? 'Lunas — terima kasih'
            : jt == null
                ? 'Segera lakukan pembayaran'
                : '${lewat ? 'Lewat jatuh tempo' : 'Jatuh tempo'} ${p.modern ? formatTanggal(jt) : formatTanggalPanjang(jt)}';
    final sisaLain = summary.piutang - total;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: p.modern ? 14 : 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [p.surfaceTonal, p.surface],
        ),
        borderRadius: BorderRadius.circular(p.modern ? 14 : 20),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  p.modern ? 'BULAN INI' : 'TAGIHAN BULAN INI',
                  style: TextStyle(
                    color: p.inkSoft,
                    fontSize: p.modern ? 11 : 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: p.modern ? 0.5 : 0.3,
                  ),
                ),
              ),
              if (t != null) _StatusBadge(lunas: lunas, p: p),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            formatRupiah(total),
            style: TextStyle(
              color: p.ink,
              fontSize: p.modern ? 25 : 29,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            due,
            style: TextStyle(
              color: lunas ? p.okText : p.warnText,
              fontSize: p.modern ? 12 : 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (sisaLain > 1 && t != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Total belum dibayar seluruh tagihan: ${formatRupiah(summary.piutang)}',
                style: TextStyle(color: p.inkSoft, fontSize: p.modern ? 11.5 : 12.5),
              ),
            ),
          if (!lunas) ...[
            SizedBox(height: p.modern ? 14 : 12),
            SizedBox(
              width: double.infinity,
              height: p.modern ? 48 : 52,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: p.pay,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(p.modern ? 12 : 100)),
                  textStyle: TextStyle(fontSize: p.modern ? 15 : 16.5, fontWeight: FontWeight.w800),
                ),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => TagihanDetailScreen(id: t.idBilling.toString())),
                ),
                icon: Icon(Icons.credit_card, size: p.modern ? 17 : 20),
                label: const Text('Bayar Sekarang'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.lunas, required this.p});

  final bool lunas;
  final DashPalette p;

  @override
  Widget build(BuildContext context) {
    final fg = lunas ? p.okText : p.warnText;
    final label = lunas ? 'Lunas' : 'Belum Lunas';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: p.modern ? 9 : 12, vertical: p.modern ? 4 : 5),
      decoration: BoxDecoration(
        color: lunas ? p.okBg : p.warnBg,
        borderRadius: BorderRadius.circular(p.modern ? 7 : 100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!p.modern) ...[
            Container(width: 6, height: 6, decoration: BoxDecoration(color: fg, shape: BoxShape.circle)),
            const SizedBox(width: 6),
          ],
          Text(
            p.modern ? label.toUpperCase() : label,
            style: TextStyle(color: fg, fontSize: p.modern ? 10.5 : 12.5, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

/// Pengumuman acara terdekat yang butuh konfirmasi kehadiran. Tersembunyi bila tidak ada.
class _AcaraBanner extends ConsumerWidget {
  const _AcaraBanner({required this.p});

  final DashPalette p;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final acara = ref
        .watch(acaraListProvider)
        .valueOrNull
        ?.aktif
        .where((a) => !a.sudahRsvp && (a.batasRsvp == null || a.batasRsvp!.isAfter(now)))
        .firstOrNull;
    if (acara == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: p.primaryTint,
          borderRadius: BorderRadius.circular(p.modern ? 14 : 20),
          border: Border.all(color: p.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.campaign_outlined, size: 16, color: p.primary),
                const SizedBox(width: 6),
                Text('PENGUMUMAN ACARA',
                    style: TextStyle(color: p.primary, fontWeight: FontWeight.w800, fontSize: 11.5, letterSpacing: 0.4)),
              ],
            ),
            const SizedBox(height: 6),
            Text(acara.nama, style: TextStyle(color: p.ink, fontSize: 15, fontWeight: FontWeight.w800)),
            if (acara.tglMulai != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(formatTanggalPanjang(acara.tglMulai!), style: TextStyle(color: p.inkSoft, fontSize: 12.5)),
              ),
            if (acara.batasRsvp != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('Batas konfirmasi: ${formatTanggal(acara.batasRsvp!)}',
                    style: TextStyle(color: p.warnText, fontSize: 12.5, fontWeight: FontWeight.w700)),
              ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: p.ink,
                  side: BorderSide(color: p.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(p.modern ? 10 : 100)),
                ),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AcaraScreen())),
                child: const Text('Konfirmasi Kehadiran', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.p});

  final DashPalette p;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 2),
        child: Text(
          'SEMUA FITUR',
          style: TextStyle(
            color: p.modern ? p.inkSoft : p.inkFaint,
            fontSize: p.modern ? 11 : 13,
            fontWeight: FontWeight.w800,
            letterSpacing: p.modern ? 1.0 : 0.6,
          ),
        ),
      );
}

class _Fitur {
  const _Fitur(this.icon, this.label, this.onTap, {this.pip = false});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool pip;
}

class _FeatureGrid extends ConsumerWidget {
  const _FeatureGrid({required this.summary, required this.p});

  final DashboardSummary summary;
  final DashPalette p;

  void _buka(BuildContext context, Widget layar) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => layar));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final belumLunas = summary.tagihanTerbaru != null && !summary.tagihanTerbaru!.lunas;
    final fitur = <_Fitur>[
      _Fitur(Icons.receipt_long_outlined, 'Tagihan', () => ref.read(shellTabProvider.notifier).state = 1, pip: belumLunas),
      _Fitur(Icons.insights_outlined, p.modern ? 'Riwayat Bayar' : 'Riwayat Pembayaran',
          () => _buka(context, const PembayaranScreen())),
      _Fitur(Icons.print_outlined, 'Cetak Invoice', () => _buka(context, const ComingSoonScreen(title: 'Cetak Invoice'))),
      _Fitur(Icons.description_outlined, 'Info PBB', () => _buka(context, const ComingSoonScreen(title: 'PBB'))),
      _Fitur(Icons.call_outlined, 'Hubungi Pengelola', () => hubungiPengelola(context)),
      _Fitur(Icons.tune_rounded, p.modern ? 'Tampilan' : 'Pengaturan Tampilan', () => _buka(context, const TampilanScreen())),
    ];

    final skala = _skalaLabel(context);
    final ikon = p.modern ? 30.0 : 38.0;
    final extent = ikon + 8 + 24 + skala.scale((p.modern ? 11 : 13) * 1.3 * 2);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: fitur.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: p.modern ? 8 : 10,
        crossAxisSpacing: p.modern ? 8 : 10,
        mainAxisExtent: extent,
      ),
      itemBuilder: (_, i) => _FeatureCard(item: fitur[i], p: p, ikon: ikon),
    );
  }
}

/// Label kartu fitur dibatasi hingga 1,2x ukuran huruf sistem supaya kata tidak terpotong di grid 3 kolom.
TextScaler _skalaLabel(BuildContext context) =>
    MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.2);

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.item, required this.p, required this.ikon});

  final _Fitur item;
  final DashPalette p;
  final double ikon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: item.label,
      child: Material(
        color: p.surface,
        borderRadius: BorderRadius.circular(p.modern ? 12 : 16),
        child: InkWell(
          borderRadius: BorderRadius.circular(p.modern ? 12 : 16),
          onTap: item.onTap,
          child: Container(
            padding: EdgeInsets.fromLTRB(6, p.modern ? 12 : 12, 6, 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(p.modern ? 12 : 16),
              border: Border.all(color: p.border),
            ),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: ikon,
                      height: ikon,
                      decoration: BoxDecoration(
                        color: p.modern ? p.primary.withValues(alpha: 0.16) : p.surfaceTonal,
                        borderRadius: BorderRadius.circular(p.modern ? 9 : 13),
                      ),
                      child: Icon(item.icon, size: p.modern ? 16 : 22, color: p.primary),
                    ),
                    if (item.pip)
                      Positioned(
                        top: -3,
                        right: -3,
                        child: Container(
                          width: p.modern ? 9 : 12,
                          height: p.modern ? 9 : 12,
                          decoration: BoxDecoration(
                            color: p.pay,
                            shape: BoxShape.circle,
                            border: Border.all(color: p.surface, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Center(
                    child: Text(
                      item.label,
                      textScaler: _skalaLabel(context),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: p.ink,
                        fontSize: p.modern ? 11 : 13,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Telepon Tenant Relation; bila perangkat tidak bisa menelepon, tampilkan nomornya.
Future<void> hubungiPengelola(BuildContext context) async {
  var berhasil = false;
  try {
    berhasil = await launchUrl(Uri(scheme: 'tel', path: AppConstants.kontakPengelola));
  } catch (_) {}
  if (berhasil || !context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Hubungi Pengelola'),
      content: const Text('Tenant Relation Easton Park:\n${AppConstants.kontakPengelolaTampil}'),
      actions: [
        TextButton(
          onPressed: () async {
            await Clipboard.setData(const ClipboardData(text: AppConstants.kontakPengelola));
            if (ctx.mounted) Navigator.pop(ctx);
          },
          child: const Text('Salin nomor'),
        ),
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
      ],
    ),
  );
}
