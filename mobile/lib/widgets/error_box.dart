import 'package:flutter/material.dart';

import '../theme/naura_theme.dart';

/// Kotak pesan error dengan garis marun di kiri.
class ErrorBox extends StatelessWidget {
  const ErrorBox(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: NauraColors.marunTint,
        border: Border(left: BorderSide(color: NauraColors.marun, width: 3)),
      ),
      child: Text(message, style: const TextStyle(color: NauraColors.marun)),
    );
  }
}
