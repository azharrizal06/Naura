import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../controllers/order_detail_controller.dart';
import '../controllers/orders_controller.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import '../theme/naura_theme.dart';
import '../utils/format.dart';
import '../widgets/message_state.dart';
import '../widgets/order_line.dart';
import '../widgets/payment_instructions.dart';
import '../widgets/status_seam.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.id, this.initial});

  final int id;
  final Order? initial;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) =>
          OrderDetailController(context.read<OrderService>(), initial: initial)..load(id),
      child: const _OrderDetailView(),
    );
  }
}

class _OrderDetailView extends StatelessWidget {
  const _OrderDetailView();

  @override
  Widget build(BuildContext context) {
    final detail = context.watch<OrderDetailController>();
    final order = detail.order;

    return Scaffold(
      // Nomor pesanan memakai huruf teks: angka Marcellus mudah tertukar (1/I).
      appBar: AppBar(
        title: Text(order?.orderNumber ?? 'Pesanan',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 17, fontWeight: FontWeight.w700, color: NauraColors.terong)),
      ),
      body: detail.loading
          ? const Center(child: CircularProgressIndicator())
          : order == null
              ? MessageState(message: detail.error ?? 'Pesanan tidak ditemukan.')
              : RefreshIndicator(
                  onRefresh: () => detail.load(order.id),
                  child: _OrderBody(order: order),
                ),
    );
  }
}

class _OrderBody extends StatelessWidget {
  const _OrderBody({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final bank = order.payment?.bank;
    final shipment = order.shipment;
    final detail = context.watch<OrderDetailController>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        Text('Dipesan ${formatDate(order.createdAt)}',
            style: const TextStyle(fontSize: 13, color: NauraColors.muted)),
        const SizedBox(height: 4),
        Text(order.status.label,
            style: display(26,
                color: order.status == OrderStatus.cancelled
                    ? NauraColors.marun
                    : NauraColors.terong)),
        if (order.status != OrderStatus.cancelled) ...[
          const SizedBox(height: 20),
          StatusSeam(status: order.status),
        ],
        if (order.status == OrderStatus.pending && bank != null) ...[
          const SizedBox(height: 28),
          PaymentInstructions(amount: order.total, bank: bank),
        ],
        if (shipment != null) ...[
          const _Section('Pengiriman'),
          Text(
            shipment.trackingNumber == null
                ? shipment.courierLabel
                : '${shipment.courierLabel}, resi ${shipment.trackingNumber}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Text(
            shipment.shippedAt != null
                ? 'Dikirim ${formatDate(shipment.shippedAt!.toLocal())}'
                : 'Nomor resi muncul setelah paket dikirim.',
            style: const TextStyle(fontSize: 13, color: NauraColors.muted),
          ),
          if (detail.canComplete) ...[
            const SizedBox(height: 16),
            _OrderActionButton(
              label: 'Pesanan diterima',
              busyLabel: 'Menyimpan…',
              title: 'Paket sudah diterima?',
              message: 'Tandai selesai hanya bila paket sudah Anda terima dan isinya sesuai.',
              confirmLabel: 'Ya, sudah diterima',
              successMessage: 'Terima kasih! Pesanan selesai.',
              action: (c) => c.complete(),
            ),
          ],
        ],
        const _Section('Barang'),
        for (final item in order.items) OrderLine(item: item),
        const Divider(height: 24, color: NauraColors.garis),
        _AmountRow('Subtotal', order.subtotal),
        _AmountRow('Ongkos kirim', order.shippingCost),
        if (order.discount > 0) _AmountRow('Potongan', -order.discount),
        _AmountRow('Total', order.total, strong: true),
        const _Section('Dikirim ke'),
        Text(order.address.recipientName, style: const TextStyle(fontWeight: FontWeight.w600)),
        Text(order.address.phone, style: const TextStyle(color: NauraColors.muted)),
        const SizedBox(height: 4),
        Text(
          '${order.address.addressLine}\n${order.address.areaLine}',
          style: const TextStyle(height: 1.5),
        ),
        if (order.notes != null) ...[
          const _Section('Catatan'),
          Text(order.notes!, style: const TextStyle(height: 1.5)),
        ],
        if (detail.canCancel) ...[
          const SizedBox(height: 32),
          _OrderActionButton(
            label: 'Batalkan pesanan',
            busyLabel: 'Membatalkan…',
            title: 'Batalkan pesanan?',
            message: 'Barang dikembalikan ke stok toko. Pesanan yang dibatalkan tidak bisa diaktifkan lagi.',
            confirmLabel: 'Ya, batalkan',
            successMessage: 'Pesanan dibatalkan.',
            action: (c) => c.cancel(),
            danger: true,
          ),
        ],
      ],
    );
  }
}

/// Tombol aksi pesanan dengan dialog konfirmasi; berhasil → daftar pesanan ikut diperbarui.
class _OrderActionButton extends StatelessWidget {
  const _OrderActionButton({
    required this.label,
    required this.busyLabel,
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.successMessage,
    required this.action,
    this.danger = false,
  });

  final String label;
  final String busyLabel;
  final String title;
  final String message;
  final String confirmLabel;
  final String successMessage;
  final Future<String?> Function(OrderDetailController) action;
  final bool danger;

  Future<void> _confirmAndRun(BuildContext context) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Tidak')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: danger ? TextButton.styleFrom(foregroundColor: NauraColors.marun) : null,
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    if (yes != true || !context.mounted) return;

    final detail = context.read<OrderDetailController>();
    final error = await action(detail);
    if (!context.mounted) return;
    final order = detail.order;
    if (error == null && order != null) context.read<OrdersController>().replace(order);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error ?? successMessage)));
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<OrderDetailController>().busy;
    final onPressed = busy ? null : () => _confirmAndRun(context);
    final text = Text(busy ? busyLabel : label);
    if (!danger) return FilledButton(onPressed: onPressed, child: text);
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: NauraColors.marun,
        side: const BorderSide(color: NauraColors.marun),
      ),
      child: text,
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 10),
      child: Text(text, style: display(20)),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow(this.label, this.amount, {this.strong = false});
  final String label;
  final int amount;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: strong ? FontWeight.w700 : FontWeight.w400,
      fontSize: strong ? 16 : 14,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: strong ? style : style.copyWith(color: NauraColors.muted)),
          const Spacer(),
          Text(amount < 0 ? '-${formatRupiah(-amount)}' : formatRupiah(amount), style: style),
        ],
      ),
    );
  }
}
