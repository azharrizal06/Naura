import 'package:flutter/material.dart';

import '../theme/naura_theme.dart';

/// Kain lembut untuk produk tanpa foto — dipilih stabil dari id produk.
const _softFabrics = [
  Color(0xFFE7DCE5),
  Color(0xFFE4DDD3),
  Color(0xFFDCE2D8),
  Color(0xFFDCDCE8),
  Color(0xFFEADBD6),
];

Color softFabricFor(int seed) => _softFabrics[seed % _softFabrics.length];

/// Foto produk 3:4. Bila foto kosong atau gagal dimuat, tampil sebagai
/// lipatan kain berwarna [fallback].
class FabricImage extends StatelessWidget {
  const FabricImage({
    super.key,
    required this.url,
    required this.fallback,
    this.radius = 4,
  });

  final String? url;
  final Color fallback;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final fold = _Fold(color: fallback);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: url == null
            ? fold
            : Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fold,
                frameBuilder: (context, child, frame, sync) =>
                    frame == null && !sync ? fold : child,
              ),
      ),
    );
  }
}

class _Fold extends StatelessWidget {
  const _Fold({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    final shade = Color.lerp(color, NauraColors.terong, 0.12)!;
    return AnimatedContainer(
      duration: MediaQuery.of(context).disableAnimations
          ? Duration.zero
          : const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color, shade, shade],
          stops: const [0, 0.56, 0.56, 1],
        ),
      ),
    );
  }
}
