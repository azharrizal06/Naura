import 'package:flutter/material.dart';

/// Deretan gulungan kain — warna yang dijual toko. Naik sekali saat tampil.
class FabricBolts extends StatelessWidget {
  const FabricBolts({super.key, this.height = 120});

  final double height;

  static const _colors = [
    Color(0xFF6C1F2B),
    Color(0xFFA07E62),
    Color(0xFFD2A3A3),
    Color(0xFFB6A2C8),
    Color(0xFFA2B299),
    Color(0xFF5A5D3B),
    Color(0xFF24304F),
    Color(0xFFEEE8DC),
  ];
  static const _heights = [0.78, 1.0, 0.64, 0.88, 0.72, 0.94, 0.58, 0.82];

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.of(context).disableAnimations;
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < _colors.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: still ? 1 : 0, end: 1),
                  duration: Duration(milliseconds: 700 + i * 70),
                  curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
                  builder: (_, t, _) => Container(
                    height: height * _heights[i] * t,
                    decoration: BoxDecoration(
                      color: _colors[i],
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(999)),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
