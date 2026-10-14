import 'package:flutter/material.dart';

import '../theme/naura_theme.dart';

/// Tab kategori: teks dengan garis kuningan di bawah saat dipilih.
class CategoryTab extends StatelessWidget {
  const CategoryTab({super.key, required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? NauraColors.kuningan : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? NauraColors.terong : NauraColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}
