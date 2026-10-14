import 'package:flutter/material.dart';

import '../theme/naura_theme.dart';
import '../utils/format.dart';

/// Bilah bawah: jumlah uang + satu tombol aksi.
class TotalBar extends StatelessWidget {
  const TotalBar({
    super.key,
    required this.label,
    required this.amount,
    required this.action,
    required this.onPressed,
    this.note,
  });

  final String label;
  final int amount;
  final String? note;
  final String action;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: NauraColors.kabut,
        border: Border(top: BorderSide(color: NauraColors.garis)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label, style: const TextStyle(fontSize: 13, color: NauraColors.muted)),
                        if (note != null)
                          Text(note!, style: const TextStyle(fontSize: 12, color: NauraColors.muted)),
                      ],
                    ),
                  ),
                  Text(formatRupiah(amount),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton(onPressed: onPressed, child: Text(action)),
            ],
          ),
        ),
      ),
    );
  }
}
