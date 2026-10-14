import 'package:flutter/material.dart';

import '../models/order.dart';
import '../theme/naura_theme.dart';
import '../utils/format.dart';
import '../utils/swatch.dart';
import 'fabric_image.dart';

/// Satu barang di detail pesanan (snapshot nama & harga saat dipesan).
class OrderLine extends StatelessWidget {
  const OrderLine({super.key, required this.item});

  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    final color = swatchFor(item.variantName);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: FabricImage(
              url: item.imageUrl,
              fallback: color ?? softFabricFor(item.productId ?? item.id),
              radius: 3,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName,
                    style: const TextStyle(fontWeight: FontWeight.w600, height: 1.3)),
                const SizedBox(height: 4),
                Text('${item.variantName}, ${item.quantity} × ${formatRupiah(item.unitPrice)}',
                    style: const TextStyle(fontSize: 13, color: NauraColors.muted)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(formatRupiah(item.subtotal), style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
