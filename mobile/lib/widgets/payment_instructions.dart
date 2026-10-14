import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/order.dart';
import '../theme/naura_theme.dart';
import '../utils/format.dart';

/// Instruksi transfer untuk pesanan yang belum dibayar.
class PaymentInstructions extends StatelessWidget {
  const PaymentInstructions({super.key, required this.amount, required this.bank});

  final int amount;
  final BankAccount bank;

  Future<void> _copy(BuildContext context, String text, String what) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('$what disalin')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: NauraColors.garis),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Transfer tepat sejumlah',
              style: TextStyle(fontSize: 13, color: NauraColors.muted)),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(formatRupiah(amount),
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, height: 1.2)),
              ),
              _CopyButton(onTap: () => _copy(context, '$amount', 'Jumlah transfer')),
            ],
          ),
          const Divider(height: 32, color: NauraColors.garis),
          Text('Ke rekening ${bank.bank}',
              style: const TextStyle(fontSize: 13, color: NauraColors.muted)),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  bank.number,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 1.5, height: 1.2),
                ),
              ),
              _CopyButton(onTap: () => _copy(context, bank.number, 'Nomor rekening')),
            ],
          ),
          const SizedBox(height: 2),
          Text('a.n. ${bank.holder}', style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 16),
          const Text(
            'Pesanan diproses setelah admin memeriksa pembayaran. Statusnya berubah menjadi Dibayar di halaman ini.',
            style: TextStyle(fontSize: 13, color: NauraColors.muted, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _CopyButton extends StatelessWidget {
  const _CopyButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.copy_rounded, size: 16),
      label: const Text('Salin'),
    );
  }
}
