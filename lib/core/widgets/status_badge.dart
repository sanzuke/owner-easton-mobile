import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Badge status tagihan — "INVOICE" (belum dibayar, merah muda) atau
/// "PAYMENT" (sudah dibayar, hijau), mengikuti desain resmi layar Tagihan.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final String status;

  bool get _isPaid {
    final s = status.toLowerCase();
    // "Belum lunas" / "unpaid" memuat kata lunas/paid tetapi berarti sebaliknya.
    if (s.contains('belum') || s.contains('unpaid')) return false;
    return s.contains('payment') || s.contains('lunas') || s.contains('paid');
  }

  @override
  Widget build(BuildContext context) {
    final bg = _isPaid ? AppColors.paymentBadgeBg : AppColors.invoiceBadgeBg;
    final fg = _isPaid ? AppColors.paymentBadgeFg : AppColors.invoiceBadgeFg;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
