import 'package:flutter/material.dart';

import '../models/address.dart';
import '../theme/naura_theme.dart';

/// Ringkasan satu alamat: label (+ penanda utama), penerima, alamat lengkap.
class AddressCard extends StatelessWidget {
  const AddressCard({super.key, required this.address, this.trailing, this.onTap});

  final Address address;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(address.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                      if (address.isDefault) ...[
                        const SizedBox(width: 8),
                        const Text('Utama',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600, color: NauraColors.plum)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${address.recipientName}, ${address.phone}',
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 2),
                  Text('${address.addressLine}\n${address.areaLine}',
                      style: const TextStyle(fontSize: 13, color: NauraColors.muted, height: 1.45)),
                  if (address.destinationId == null)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text('Kecamatan belum dipilih dari pencarian',
                          style: TextStyle(fontSize: 12, color: NauraColors.kuningan)),
                    ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
