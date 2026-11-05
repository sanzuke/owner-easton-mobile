import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../pembayaran/application/pembayaran_providers.dart';
import '../../pembayaran/presentation/pembayaran_screen.dart';
import '../../tagihan/application/tagihan_providers.dart';
import '../application/va_providers.dart';
import '../data/va_repository.dart';

/// "Bayar via VA" untuk satu invoice: nomor Virtual Account BJB (bisa disalin), nominal, kedaluwarsa, langkah bayar.
/// App TIDAK membuat VA — nomor diterbitkan pengelola lewat gateway BJB dan hanya ditampilkan di sini (docs/96b).
/// Tarik layar ke bawah untuk memeriksa status: pembayaran yang sudah masuk muncul di Riwayat Pembayaran.
class VaScreen extends ConsumerWidget {
  const VaScreen({super.key, required this.idBilling});

  final String idBilling;

  Future<void> _segarkan(BuildContext context, WidgetRef ref) async {
    ref.invalidate(riwayatBayarProvider);
    ref.invalidate(tagihanDetailProvider(idBilling));
    ref.invalidate(vaTagihanProvider(idBilling));
    final messenger = ScaffoldMessenger.of(context);
    try {
      final baru = await ref.read(vaTagihanProvider(idBilling).future);
      final pesan = switch (baru.va?.status) {
        VaStatus.dibayar => 'Pembayaran sudah kami terima.',
        VaStatus.diproses => 'Pembayaran sedang diproses, cek lagi sebentar.',
        _ => 'Belum ada pembayaran yang masuk.',
      };
      messenger.showSnackBar(SnackBar(content: Text(pesan)));
    } catch (_) {
      // Kesalahan tampil lewat state error provider.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vaAsync = ref.watch(vaTagihanProvider(idBilling));

    return Scaffold(
      appBar: AppBar(title: const Text('Bayar via Virtual Account')),
      body: RefreshIndicator(
        onRefresh: () => _segarkan(context, ref),
        child: vaAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 64, 24, 0),
                child: Column(
                  children: [
                    const Text(
                      'Info Virtual Account belum bisa dimuat. Periksa koneksi lalu tarik layar ke bawah untuk mencoba lagi.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => ref.invalidate(vaTagihanProvider(idBilling)),
                      child: const Text('Coba lagi'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          data: (info) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              if (info.va case final va?) ...[
                _KartuVa(va: va, nomorInvoice: info.nomorInvoice),
                const SizedBox(height: 16),
                if (va.status == VaStatus.dibayar)
                  _Catatan(
                    ikon: Icons.check_circle_outline,
                    warna: AppColors.paymentBadgeFg,
                    latar: AppColors.paymentBadgeBg,
                    teks: 'Pembayaran VA ini sudah diterima. Kwitansi ada di Riwayat Pembayaran.',
                  )
                else if (va.status == VaStatus.diproses)
                  const _Catatan(
                    ikon: Icons.hourglass_top,
                    teks: 'Bank sudah mengabari pembayaran Anda dan sedang dicatat. Tarik layar untuk memeriksa lagi.',
                  )
                else if (va.status == VaStatus.invoiceLunas)
                  const _Catatan(
                    ikon: Icons.info_outline,
                    teks: 'Invoice ini sudah lunas lewat jalur lain. Jangan bayar lagi melalui VA ini.',
                  )
                else if (va.status == VaStatus.kedaluwarsa)
                  const _Catatan(
                    ikon: Icons.event_busy,
                    teks: 'VA ini sudah kedaluwarsa. Hubungi pengelola untuk menerbitkan VA baru.',
                  ),
                if (va.dapatDibayar) ...[
                  Text('Cara bayar', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  for (var i = 0; i < info.langkah.length; i++)
                    _Langkah(nomor: i + 1, teks: info.langkah[i]),
                  const SizedBox(height: 8),
                  for (final p in info.peringatan)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _Catatan(ikon: Icons.warning_amber_rounded, teks: p),
                    ),
                ],
              ] else ...[
                _Catatan(
                  ikon: Icons.info_outline,
                  teks: info.pesan.isEmpty ? 'Virtual Account belum tersedia untuk invoice ini.' : info.pesan,
                ),
                if (info.invoiceAktif case final aktif?)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => VaScreen(idBilling: aktif.id)),
                      ),
                      icon: const Icon(Icons.account_balance, size: 18),
                      label: Text('Buka ${aktif.nomor ?? 'invoice terbaru'}'),
                    ),
                  ),
              ],
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PembayaranScreen()),
                ),
                icon: const Icon(Icons.receipt_long, size: 18),
                label: const Text('Lihat Riwayat Pembayaran'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KartuVa extends StatelessWidget {
  const _KartuVa({required this.va, this.nomorInvoice});

  final VaInfo va;
  final String? nomorInvoice;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    final kedaluwarsa = va.kedaluwarsa;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(va.bank, style: tema.titleMedium)),
                _ChipStatus(status: va.status),
              ],
            ),
            if (nomorInvoice != null) Text(nomorInvoice!, style: tema.bodySmall),
            const SizedBox(height: 16),
            Text('Nomor Virtual Account', style: tema.labelMedium),
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    va.nomorVa,
                    style: tema.headlineSmall?.copyWith(letterSpacing: 1, fontWeight: FontWeight.bold),
                  ),
                ),
                _TombolSalin(label: 'Nomor VA', teks: va.nomorVa),
              ],
            ),
            if (va.namaAkun != null && va.namaAkun!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Atas nama', style: tema.labelMedium),
              Text(va.namaAkun!),
            ],
            const SizedBox(height: 12),
            Text('Nominal', style: tema.labelMedium),
            Row(
              children: [
                Expanded(
                  child: Text(
                    formatRupiah(va.nominal),
                    style: tema.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                _TombolSalin(label: 'Nominal', teks: va.nominal.round().toString()),
              ],
            ),
            if (kedaluwarsa != null) ...[
              const SizedBox(height: 12),
              Text('Berlaku sampai', style: tema.labelMedium),
              Text(formatTanggalWaktu(kedaluwarsa)),
            ],
            if (va.status == VaStatus.dibayar && va.dibayarPada != null) ...[
              const SizedBox(height: 12),
              Text('Dibayar pada', style: tema.labelMedium),
              Text(
                [
                  formatTanggalWaktu(va.dibayarPada!),
                  if (va.jumlahDibayar != null) formatRupiah(va.jumlahDibayar!),
                ].join(' • '),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TombolSalin extends StatelessWidget {
  const _TombolSalin({required this.label, required this.teks});

  final String label;
  final String teks;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      style: TextButton.styleFrom(minimumSize: Size.zero, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
      onPressed: () async {
        final messenger = ScaffoldMessenger.of(context);
        await Clipboard.setData(ClipboardData(text: teks));
        messenger.showSnackBar(SnackBar(content: Text('$label disalin.')));
      },
      icon: const Icon(Icons.copy, size: 16),
      label: const Text('Salin'),
    );
  }
}

class _ChipStatus extends StatelessWidget {
  const _ChipStatus({required this.status});

  final VaStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      VaStatus.dibayar => (AppColors.paymentBadgeBg, AppColors.paymentBadgeFg),
      VaStatus.belumDibayar || VaStatus.diproses => (AppColors.invoiceBadgeBg, AppColors.invoiceBadgeFg),
      _ => (Colors.grey.shade300, Colors.grey.shade800),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        status.label.toUpperCase(),
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _Langkah extends StatelessWidget {
  const _Langkah({required this.nomor, required this.teks});

  final int nomor;
  final String teks;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 11, child: Text('$nomor', style: const TextStyle(fontSize: 12))),
          const SizedBox(width: 10),
          Expanded(child: Text(teks)),
        ],
      ),
    );
  }
}

class _Catatan extends StatelessWidget {
  const _Catatan({required this.ikon, required this.teks, this.warna, this.latar});

  final IconData ikon;
  final String teks;
  final Color? warna;
  final Color? latar;

  @override
  Widget build(BuildContext context) {
    final skema = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: latar ?? skema.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ikon, size: 20, color: warna ?? skema.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(child: Text(teks, style: TextStyle(color: warna))),
        ],
      ),
    );
  }
}
