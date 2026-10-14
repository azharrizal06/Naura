import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/address_controller.dart';
import '../controllers/cart_controller.dart';
import '../controllers/checkout_controller.dart';
import '../controllers/nav_controller.dart';
import '../controllers/orders_controller.dart';
import '../models/address.dart';
import '../services/shipping_service.dart';
import '../services/store_service.dart';
import '../theme/naura_theme.dart';
import '../utils/format.dart';
import '../widgets/address_card.dart';
import '../widgets/cart_line.dart';
import '../widgets/rate_option.dart';
import '../widgets/total_bar.dart';
import 'address_form_screen.dart';
import 'addresses_screen.dart';
import 'order_detail_screen.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CheckoutController(context.read<ShippingService>(), context.read<StoreService>())
        ..init(context.read<AddressController>().addresses),
      child: const _CheckoutView(),
    );
  }
}

class _CheckoutView extends StatefulWidget {
  const _CheckoutView();

  @override
  State<_CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<_CheckoutView> {
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _chooseAddress() async {
    final checkout = context.read<CheckoutController>();
    final chosen = await Navigator.of(context).push<Address>(MaterialPageRoute(
      builder: (_) => AddressesScreen(pick: true, selectedId: checkout.address?.id),
    ));
    if (chosen != null) await checkout.selectAddress(chosen);
  }

  Future<void> _addAddress() async {
    final checkout = context.read<CheckoutController>();
    final saved = await Navigator.of(context).push<Address>(
      MaterialPageRoute(builder: (_) => const AddressFormScreen()),
    );
    if (saved != null) await checkout.selectAddress(saved);
  }

  Future<void> _placeOrder() async {
    final checkout = context.read<CheckoutController>();
    final result = await context.read<OrdersController>().place(checkout.toOrder(notes: _notesCtrl.text));
    if (!mounted) return;
    final order = result.order;
    if (order == null) {
      // Server bisa menolak karena harga berubah atau barang nonaktif dan sudah
      // menyamakan keranjang — muat ulang agar total baru langsung terlihat.
      context.read<CartController>().load();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(result.error ?? 'Pesanan tidak terkirim.')));
      return;
    }
    // Server mengosongkan keranjang setelah pesanan dibuat.
    context.read<CartController>().load();
    context.read<NavController>().go(NavTab.orders);
    final navigator = Navigator.of(context);
    navigator.popUntil((r) => r.isFirst);
    navigator.push(MaterialPageRoute(
      builder: (_) => OrderDetailScreen(id: order.id, initial: order),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>().cart;
    final checkout = context.watch<CheckoutController>();
    final placing = context.watch<OrdersController>().placing;
    final address = checkout.address;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _SectionTitle('Kirim ke', action: address == null ? null : ('Ganti', _chooseAddress)),
          if (address == null)
            _EmptyAddress(onAdd: _addAddress)
          else
            AddressCard(address: address),

          const _SectionTitle('Kurir'),
          _RatesSection(checkout: checkout, hasAddress: address != null),

          const _SectionTitle('Pembayaran'),
          const Text('Transfer bank. Nomor rekening tampil lagi setelah pesanan dibuat.',
              style: TextStyle(fontSize: 13, color: NauraColors.muted, height: 1.45)),
          const SizedBox(height: 8),
          _BanksSection(checkout: checkout),

          const _SectionTitle('Catatan untuk penjual'),
          TextField(
            controller: _notesCtrl,
            minLines: 2,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Catatan (opsional)',
              hintText: 'Misalnya: tolong bungkus terpisah',
              alignLabelWithHint: true,
            ),
          ),

          const _SectionTitle('Ringkasan'),
          for (final item in cart.items) CartLine(item: item),
          const Divider(height: 24, color: NauraColors.garis),
          _SummaryRow('Subtotal', formatRupiah(cart.subtotal)),
          _SummaryRow(
            checkout.rate == null ? 'Ongkos kirim' : 'Ongkos kirim (${checkout.rate!.label})',
            checkout.rate == null ? 'Pilih kurir' : formatRupiah(checkout.shippingCost),
          ),
        ],
      ),
      bottomNavigationBar: TotalBar(
        label: 'Total bayar',
        amount: checkout.totalFor(cart.subtotal),
        action: placing ? 'Membuat pesanan…' : 'Buat pesanan',
        onPressed: cart.isEmpty || placing || !checkout.ready ? null : _placeOrder,
      ),
    );
  }
}

class _RatesSection extends StatelessWidget {
  const _RatesSection({required this.checkout, required this.hasAddress});

  final CheckoutController checkout;
  final bool hasAddress;

  @override
  Widget build(BuildContext context) {
    if (!hasAddress) {
      return const Text('Pilih alamat dulu untuk melihat ongkir.',
          style: TextStyle(fontSize: 13, color: NauraColors.muted));
    }
    if (checkout.loadingRates) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 12),
            Text('Menghitung ongkir…', style: TextStyle(color: NauraColors.muted)),
          ],
        ),
      );
    }
    if (checkout.ratesError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(checkout.ratesError!,
              style: const TextStyle(fontSize: 13, color: NauraColors.marun, height: 1.45)),
          TextButton(onPressed: checkout.loadRates, child: const Text('Hitung ulang ongkir')),
        ],
      );
    }
    if (checkout.rates.isEmpty) {
      return const Text('Belum ada kurir yang melayani alamat ini. Coba alamat lain.',
          style: TextStyle(fontSize: 13, color: NauraColors.muted));
    }

    final selected = checkout.rate;
    return RadioGroup<String>(
      groupValue: selected == null ? null : '${selected.courier}|${selected.service}',
      onChanged: (v) {
        final rate = checkout.rates.where((r) => '${r.courier}|${r.service}' == v).firstOrNull;
        if (rate != null) checkout.selectRate(rate);
      },
      child: Column(
        children: [
          for (final r in checkout.rates)
            RateOption(
              rate: r,
              selected: selected != null && r.sameAs(selected),
              onTap: () => checkout.selectRate(r),
            ),
        ],
      ),
    );
  }
}

class _BanksSection extends StatelessWidget {
  const _BanksSection({required this.checkout});

  final CheckoutController checkout;

  @override
  Widget build(BuildContext context) {
    if (checkout.loadingBanks) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 12),
            Text('Memuat rekening toko…', style: TextStyle(color: NauraColors.muted)),
          ],
        ),
      );
    }
    if (checkout.banksError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(checkout.banksError!,
              style: const TextStyle(fontSize: 13, color: NauraColors.marun, height: 1.45)),
          TextButton(onPressed: checkout.loadBanks, child: const Text('Muat ulang rekening')),
        ],
      );
    }
    if (checkout.banks.isEmpty) {
      return const Text('Toko belum menyiapkan rekening transfer. Hubungi penjual.',
          style: TextStyle(fontSize: 13, color: NauraColors.muted));
    }

    return RadioGroup<String>(
      groupValue: checkout.bank,
      onChanged: (v) {
        if (v != null) checkout.selectBank(v);
      },
      child: Column(
        children: [
          for (final acc in checkout.banks)
            _BankOption(
              bank: acc.bank,
              detail: '${acc.number} a.n. ${acc.holder}',
              selected: checkout.bank == acc.bank,
              onTap: () => checkout.selectBank(acc.bank),
            ),
        ],
      ),
    );
  }
}

class _EmptyAddress extends StatelessWidget {
  const _EmptyAddress({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Belum ada alamat tersimpan.', style: TextStyle(color: NauraColors.muted)),
        TextButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('Tambah alamat')),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {this.action});
  final String text;
  final (String, VoidCallback)? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 4),
      child: Row(
        children: [
          Expanded(child: Text(text, style: display(22))),
          if (action != null) TextButton(onPressed: action!.$2, child: Text(action!.$1)),
        ],
      ),
    );
  }
}

class _BankOption extends StatelessWidget {
  const _BankOption({
    required this.bank,
    required this.detail,
    required this.selected,
    required this.onTap,
  });

  final String bank;
  final String detail;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: NauraColors.garis)),
        ),
        child: Row(
          children: [
            Radio<String>(value: bank, activeColor: NauraColors.plum),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Transfer $bank',
                      style: TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
                  Text(detail, style: const TextStyle(fontSize: 13, color: NauraColors.muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: NauraColors.muted))),
          const SizedBox(width: 12),
          Text(value),
        ],
      ),
    );
  }
}
