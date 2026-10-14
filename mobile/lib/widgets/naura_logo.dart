import 'package:flutter/material.dart';

/// Logo Naura Fashion. [onDark] memakai varian teks putih untuk latar Terong.
class NauraLogo extends StatelessWidget {
  const NauraLogo({super.key, this.width = 160, this.onDark = false});

  final double width;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      onDark ? 'assets/images/logo_light.png' : 'assets/images/logo.png',
      width: width,
      filterQuality: FilterQuality.medium,
      semanticLabel: 'Naura Fashion',
    );
  }
}
