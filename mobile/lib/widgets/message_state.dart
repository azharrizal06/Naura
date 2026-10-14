import 'package:flutter/material.dart';

import '../theme/naura_theme.dart';

/// Layar kosong/error di tengah: judul opsional, pesan, dan satu aksi.
class MessageState extends StatelessWidget {
  const MessageState({
    super.key,
    required this.message,
    this.title,
    this.actionLabel,
    this.onAction,
  });

  final String? title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null) ...[
              Text(title!, textAlign: TextAlign.center, style: display(24)),
              const SizedBox(height: 8),
            ],
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: NauraColors.muted, height: 1.5)),
            if (actionLabel != null) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: 200,
                child: FilledButton(onPressed: onAction, child: Text(actionLabel!)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
