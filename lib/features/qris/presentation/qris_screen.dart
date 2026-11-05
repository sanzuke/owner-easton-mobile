import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/network/api_envelope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../pembayaran/application/pembayaran_providers.dart';
import '../../dashboard/application/dashboard_providers.dart';
import '../application/qris_providers.dart';
import '../data/qris_repository.dart';

/// "Bayar via QRIS": membuat QR dinamis (nominal = seluruh tagihan atau nominal lain), menampilkannya dengan hitung mundur,
/// memantau status tiap beberapa detik, dan menyediakan unduh/bagikan gambar QR (CR-08, docs/117).
/// Pembayaran diposting server saat notifikasi bank masuk; app hanya menampilkan statusnya.
class QrisScreen extends ConsumerStatefulWidget {
  const QrisScreen({super.key, this.intervalPantau = const Duration(seconds: 4)});

  /// Jeda antar pemeriksaan status (diganti di tes).
  final Duration intervalPantau;

  @override
  ConsumerState<QrisScreen> createState() => _QrisScreenState();
}

class _QrisScreenState extends ConsumerState<QrisScreen> {
  final _nominalCtrl = TextEditingController();
  bool _semua = true;
  bool _bekerja = false;
  String? _galat;
  QrisTransaksi? _trx;
  int _sisaDetik = 0;
  Timer? _hitungMundur;
  Timer? _pantau;
  bool _memeriksa = false;

  @override
  void dispose() {
    _hitungMundur?.cancel();
    _pantau?.cancel();
    _nominalCtrl.dispose();
    super.dispose();
  }

  String _pesan(Object e) => e is ApiException ? e.message : 'Tidak bisa terhubung ke server. Coba lagi.';

  Future<void> _buat() async {
    num? nominal;
    if (!_semua) {
      nominal = int.tryParse(_nominalCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''));
      if (nominal == null || nominal <= 0) {
        setState(() => _galat = 'Masukkan nominal pembayaran.');
        return;
      }
    }
    setState(() {
      _bekerja = true;
      _galat = null;
    });
    try {
      final trx = await ref.read(qrisRepositoryProvider).buat(nominal: nominal);
      if (!mounted) return;
      _mulai(trx);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _bekerja = false;
        _galat = _pesan(e);
      });
    }
  }

  void _mulai(QrisTransaksi trx) {
    _hitungMundur?.cancel();
    _pantau?.cancel();
    setState(() {
      _trx = trx;
      _bekerja = false;
      _sisaDetik = trx.sisaDetik;
    });
    if (trx.status != QrisStatus.pending) return;
    _hitungMundur = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _sisaDetik = _sisaDetik > 0 ? _sisaDetik - 1 : 0);
      if (_sisaDetik == 0) _periksa();
    });
    _pantau = Timer.periodic(widget.intervalPantau, (_) => _periksa());
  }

  Future<void> _periksa({bool manual = false}) async {
    final trx = _trx;
    if (trx == null || _memeriksa) return;
    _memeriksa = true;
    try {
      final baru = await ref.read(qrisRepositoryProvider).status(trx.ref);
      if (!mounted) return;
      if (baru.status != QrisStatus.pending) {
        _hitungMundur?.cancel();
        _pantau?.cancel();
        if (baru.status == QrisStatus.paid) {
          // Pembayaran masuk: segarkan riwayat dan ringkasan tagihan.
          ref.invalidate(riwayatBayarProvider);
          ref.invalidate(dashboardSummaryProvider);
        }
      }
      setState(() => _trx = baru);
    } catch (e) {
      if (manual && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_pesan(e))));
      }
    } finally {
      _memeriksa = false;
    }
  }

  Future<void> _unduh() async {
    final trx = _trx;
    if (trx == null) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final png = await ref.read(qrisRepositoryProvider).gambar(trx.ref);
      await ref.read(pembagiQrProvider).bagikan(png, nama: 'QRIS-${trx.ref}');
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(_pesan(e))));
    }
  }

  Future<void> _simulasi() async {
    final trx = _trx;
    if (trx == null) return;
    try {
      final baru = await ref.read(qrisRepositoryProvider).simulasiBayar(trx.ref);
      if (!mounted) return;
      _hitungMundur?.cancel();
      _pantau?.cancel();
      ref.invalidate(riwayatBayarProvider);
      ref.invalidate(dashboardSummaryProvider);
      setState(() => _trx = baru);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_pesan(e))));
    }
  }

  void _ulang() {
    _hitungMundur?.cancel();
    _pantau?.cancel();
    setState(() {
      _trx = null;
      _galat = null;
    });
  }

  String _mmss(int detik) =>
      '${(detik ~/ 60).toString().padLeft(2, '0')}:${(detik % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final trx = _trx;
    return Scaffold(
      appBar: AppBar(title: const Text('Bayar via QRIS')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: trx == null ? _formulir(context) : _tampilQr(context, trx),
      ),
    );
  }

  List<Widget> _formulir(BuildContext context) => [
    const Text(
      'Buat kode QRIS lalu pindai dengan aplikasi mobile banking atau e-wallet apa pun yang mendukung QRIS. '
      'Pembayaran tercatat otomatis setelah bank mengonfirmasi.',
    ),
    const SizedBox(height: 16),
    RadioGroup<bool>(
      groupValue: _semua,
      onChanged: (v) => setState(() => _semua = v ?? true),
      child: const Column(
        children: [
          RadioListTile<bool>(value: true, title: Text('Seluruh tagihan yang belum dibayar')),
          RadioListTile<bool>(value: false, title: Text('Nominal lain')),
        ],
      ),
    ),
    if (!_semua)
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        child: TextField(
          controller: _nominalCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(labelText: 'Nominal (Rp)', prefixText: 'Rp '),
        ),
      ),
    if (_galat != null) ...[
      const SizedBox(height: 12),
      Text(_galat!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
    ],
    const SizedBox(height: 16),
    FilledButton.icon(
      onPressed: _bekerja ? null : _buat,
      icon: _bekerja
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.qr_code_2),
      label: const Text('Buat QRIS'),
    ),
  ];

  List<Widget> _tampilQr(BuildContext context, QrisTransaksi trx) {
    final teks = Theme.of(context).textTheme;
    return [
      if (trx.simulasi)
        const _Pita(
          warna: Colors.orange,
          teks: 'MODE UJI: QR simulasi, tidak bisa dibayar di aplikasi bank.',
        )
      else if (trx.sandbox)
        const _Pita(
          warna: Colors.orange,
          teks: 'SANDBOX BJB: pembayaran uji, tidak memindahkan uang.',
        ),
      if (trx.status == QrisStatus.paid) ...[
        const SizedBox(height: 24),
        const Icon(Icons.check_circle, color: AppColors.paymentBadgeFg, size: 72),
        const SizedBox(height: 8),
        Text('Pembayaran diterima', textAlign: TextAlign.center, style: teks.titleLarge),
        const SizedBox(height: 4),
        Text(formatRupiah(trx.kwitansi?.jumlah ?? trx.nominal), textAlign: TextAlign.center, style: teks.titleMedium),
        if (trx.kwitansi != null) ...[
          const SizedBox(height: 4),
          Text('Kwitansi ${trx.kwitansi!.nomor}', textAlign: TextAlign.center),
        ],
        const SizedBox(height: 24),
        FilledButton(onPressed: () => Navigator.of(context).maybePop(), child: const Text('Selesai')),
      ] else if (trx.status == QrisStatus.expired || _sisaDetik == 0) ...[
        const SizedBox(height: 24),
        const Icon(Icons.timer_off_outlined, size: 56),
        const SizedBox(height: 8),
        Text('QRIS sudah kedaluwarsa', textAlign: TextAlign.center, style: teks.titleMedium),
        const SizedBox(height: 4),
        const Text('Buat kode baru untuk melanjutkan pembayaran.', textAlign: TextAlign.center),
        const SizedBox(height: 16),
        FilledButton(onPressed: _ulang, child: const Text('Buat QRIS baru')),
      ] else ...[
        const SizedBox(height: 12),
        Center(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: QrImageView(data: trx.qr, size: 240, backgroundColor: Colors.white),
          ),
        ),
        const SizedBox(height: 12),
        Text(formatRupiah(trx.nominal), textAlign: TextAlign.center, style: teks.headlineSmall),
        const SizedBox(height: 4),
        Text('Berlaku ${_mmss(_sisaDetik)} lagi', textAlign: TextAlign.center),
        const SizedBox(height: 4),
        const Text('Menunggu pembayaran…', textAlign: TextAlign.center),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _unduh,
          icon: const Icon(Icons.download),
          label: const Text('Simpan / bagikan QR'),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => _periksa(manual: true),
          icon: const Icon(Icons.refresh),
          label: const Text('Periksa status'),
        ),
        if (trx.bisaSimulasiBayar) ...[
          const SizedBox(height: 8),
          TextButton(onPressed: _simulasi, child: const Text('Simulasikan pembayaran (uji)')),
        ],
      ],
    ];
  }
}

class _Pita extends StatelessWidget {
  const _Pita({required this.warna, required this.teks});

  final Color warna;
  final String teks;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: warna.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
    child: Text(teks, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
  );
}
