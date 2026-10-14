import 'package:flutter/material.dart';

import '../models/product.dart';
import '../theme/naura_theme.dart';
import '../utils/format.dart';
import 'fabric_image.dart';

/// Kartu produk di grid katalog: foto 3:4, kategori, nama, harga.
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, required this.onTap});
  final ProductListItem product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FabricImage(url: product.primaryImage, fallback: softFabricFor(product.id)),
          const SizedBox(height: 10),
          if (product.categoryName != null)
            Text(
              product.categoryName!,
              style: const TextStyle(fontSize: 12, color: NauraColors.muted),
            ),
          const SizedBox(height: 2),
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.3),
          ),
          const SizedBox(height: 4),
          Text(
            formatRupiah(product.basePrice),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
