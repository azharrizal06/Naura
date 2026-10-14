import 'package:flutter/material.dart';

import '../models/shipping_rate.dart';
import '../theme/naura_theme.dart';
import '../utils/format.dart';

/// Satu baris pilihan kurir (dipakai di dalam RadioGroup).
class RateOption extends StatelessWidget {
  const RateOption({super.key, required this.rate, required this.selected, required this.onTap});

  final ShippingRate rate;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final detail = [rate.etdLabel, if (rate.description.isNotEmpty) rate.description]
        .whereType<String>()
        .join(', ');

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: NauraColors.garis)),
        ),
        child: Row(
          children: [
            Radio<String>(value: '${rate.courier}|${rate.service}', activeColor: NauraColors.plum),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rate.label,
                      style: TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
                  if (detail.isNotEmpty)
                    Text(detail, style: const TextStyle(fontSize: 13, color: NauraColors.muted)),
                ],
              ),
            ),
            Text(formatRupiah(rate.cost),
                style: TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
