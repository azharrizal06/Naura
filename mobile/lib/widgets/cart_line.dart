import 'package:flutter/material.dart';

import '../models/cart.dart';
import '../theme/naura_theme.dart';
import '../utils/format.dart';
import '../utils/swatch.dart';
import 'fabric_image.dart';

/// Satu baris keranjang: lipatan kain berwarna varian + nama + jumlah.
/// Tanpa [onQuantityChanged] tampil ringkas (untuk ringkasan checkout).
class CartLine extends StatelessWidget {
  const CartLine({super.key, required this.item, this.onQuantityChanged, this.busy = false});

  final CartItem item;
  final ValueChanged<int>? onQuantityChanged;
  final bool busy;

  bool get _editable => onQuantityChanged != null;

  @override
  Widget build(BuildContext context) {
    final color = swatchFor(item.variantName);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: _editable ? 16 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _editable ? 72 : 48,
            child: FabricImage(
              url: item.imageUrl,
              fallback: color ?? softFabricFor(item.productId),
              radius: 3,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, height: 1.3)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (color != null) ...[
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(color: NauraColors.terong.withValues(alpha: 0.2)),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        _editable ? item.variantName : '${item.variantName}, ${item.quantity} pcs',
                        style: const TextStyle(fontSize: 13, color: NauraColors.muted),
                      ),
                    ),
                  ],
                ),
                if (_editable) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _QuantityStepper(
                        quantity: item.quantity,
                        atMax: item.quantity >= item.stock,
                        enabled: !busy,
                        onChanged: onQuantityChanged!,
                      ),
                      const Spacer(),
                      Text(formatRupiah(item.lineTotal),
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                  if (item.quantity >= item.stock)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text('Stok tersisa ${item.stock}',
                          style: const TextStyle(fontSize: 12, color: NauraColors.kuningan)),
                    ),
                ],
              ],
            ),
          ),
          if (!_editable)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(formatRupiah(item.lineTotal),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.atMax,
    required this.enabled,
    required this.onChanged,
  });

  final int quantity;
  final bool atMax;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: NauraColors.garisKuat),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: quantity == 1 ? Icons.delete_outline : Icons.remove,
            tooltip: quantity == 1 ? 'Hapus dari keranjang' : 'Kurangi',
            onTap: enabled ? () => onChanged(quantity - 1) : null,
          ),
          SizedBox(
            width: 32,
            child: Text('$quantity',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          _StepButton(
            icon: Icons.add,
            tooltip: 'Tambah',
            onTap: enabled && !atMax ? () => onChanged(quantity + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.tooltip, required this.onTap});
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      color: NauraColors.terong,
      disabledColor: NauraColors.garisKuat,
      constraints: const BoxConstraints.tightFor(width: 36, height: 34),
      padding: EdgeInsets.zero,
    );
  }
}
