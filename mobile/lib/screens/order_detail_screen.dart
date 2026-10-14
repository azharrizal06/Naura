import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../controllers/order_detail_controller.dart';
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
      ],
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
