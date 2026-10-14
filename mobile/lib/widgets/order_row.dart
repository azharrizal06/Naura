import 'package:flutter/material.dart';

import '../models/order.dart';
import '../theme/naura_theme.dart';
import '../utils/format.dart';
import '../utils/swatch.dart';

/// Warna titik status pesanan.
Color orderStatusColor(OrderStatus s) => switch (s) {
      OrderStatus.pending => NauraColors.kuningan,
      OrderStatus.paid || OrderStatus.processing => NauraColors.plum,
      OrderStatus.shipped || OrderStatus.completed => const Color(0xFF4F7A5C),
      OrderStatus.cancelled => NauraColors.marun,
    };

/// Baris di daftar pesanan: nomor, tanggal, status, warna barang, total.
class OrderRow extends StatelessWidget {
  const OrderRow({super.key, required this.order, required this.onTap});

  final Order order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = order.items
        .map((i) => swatchFor(i.variantName))
        .whereType<Color>()
        .toSet()
        .take(5)
        .toList();

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(order.orderNumber,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
                Text(formatDate(order.createdAt),
                    style: const TextStyle(fontSize: 13, color: NauraColors.muted)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: orderStatusColor(order.status),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(order.status.label,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: orderStatusColor(order.status))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final c in colors)
                  Container(
                    width: 18,
                    height: 18,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(color: NauraColors.terong.withValues(alpha: 0.15)),
                    ),
                  ),
                if (colors.isNotEmpty) const SizedBox(width: 6),
                Text('${order.itemCount} barang',
                    style: const TextStyle(fontSize: 13, color: NauraColors.muted)),
                const Spacer(),
                Text(formatRupiah(order.total),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
