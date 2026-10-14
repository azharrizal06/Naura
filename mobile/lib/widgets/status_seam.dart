import 'package:flutter/material.dart';

import '../models/order.dart';
import '../theme/naura_theme.dart';

/// Status pesanan sebagai garis jahitan: bagian yang sudah dilalui terjahit
/// rapat (garis penuh), sisanya masih jelujur (putus-putus).
class StatusSeam extends StatelessWidget {
  const StatusSeam({super.key, required this.status});

  final OrderStatus status;

  static const _labels = ['Dipesan', 'Dibayar', 'Diproses', 'Dikirim', 'Selesai'];

  @override
  Widget build(BuildContext context) {
    final current = status.step;

    return Semantics(
      label: 'Status pesanan: ${status.label}',
      excludeSemantics: true,
      child: Column(
        children: [
          SizedBox(
            height: 20,
            child: CustomPaint(
              size: Size.infinite,
              painter: _SeamPainter(steps: _labels.length, current: current),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < _labels.length; i++)
                Expanded(
                  child: Text(
                    _labels[i],
                    textAlign: i == 0
                        ? TextAlign.left
                        : i == _labels.length - 1
                            ? TextAlign.right
                            : TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: i == current ? FontWeight.w700 : FontWeight.w500,
                      color: i <= current ? NauraColors.terong : NauraColors.muted,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SeamPainter extends CustomPainter {
  _SeamPainter({required this.steps, required this.current});

  final int steps;
  final int current;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    // Titik pertama & terakhir rata dengan tepi label kiri/kanan.
    const inset = 6.0;
    final gap = (size.width - inset * 2) / (steps - 1);
    double x(int i) => inset + gap * i;

    final sewn = Paint()
      ..color = NauraColors.terong
      ..strokeWidth = 2;
    final basting = Paint()
      ..color = NauraColors.garisKuat
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < steps - 1; i++) {
      if (i < current) {
        canvas.drawLine(Offset(x(i), y), Offset(x(i + 1), y), sewn);
      } else {
        for (var dx = x(i) + 4; dx < x(i + 1) - 4; dx += 9) {
          canvas.drawLine(Offset(dx, y), Offset(dx + 4, y), basting);
        }
      }
    }

    for (var i = 0; i < steps; i++) {
      final c = Offset(x(i), y);
      if (i < current) {
        canvas.drawCircle(c, 4.5, Paint()..color = NauraColors.terong);
      } else if (i == current) {
        canvas.drawCircle(c, 7, Paint()..color = NauraColors.plumTint);
        canvas.drawCircle(c, 4.5, Paint()..color = NauraColors.plum);
      } else {
        canvas.drawCircle(c, 4.5, Paint()..color = NauraColors.kabut);
        canvas.drawCircle(
          c,
          4.5,
          Paint()
            ..color = NauraColors.garisKuat
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_SeamPainter old) => old.current != current || old.steps != steps;
}
