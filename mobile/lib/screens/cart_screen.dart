import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/cart_controller.dart';
import '../controllers/nav_controller.dart';
import '../theme/naura_theme.dart';
import '../widgets/cart_line.dart';
import '../widgets/message_state.dart';
import '../widgets/total_bar.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  Future<void> _setQuantity(BuildContext context, int itemId, int quantity) async {
    final error = await context.read<CartController>().setQuantity(itemId, quantity);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CartController>();
    final cart = controller.cart;

    return Scaffold(
      appBar: AppBar(title: const Text('Keranjang'), automaticallyImplyLeading: false),
      body: cart.isEmpty
          ? MessageState(
              title: 'Keranjang masih kosong',
              message: 'Pilih warna dan ukuran di halaman produk, lalu tambahkan ke sini.',
              actionLabel: 'Lihat koleksi',
              onAction: () => context.read<NavController>().go(NavTab.catalog),
            )
          : RefreshIndicator(
              onRefresh: controller.load,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                itemCount: cart.items.length,
                separatorBuilder: (_, _) => const Divider(height: 1, color: NauraColors.garis),
                itemBuilder: (_, i) {
                  final item = cart.items[i];
                  return CartLine(
                    item: item,
                    busy: controller.busy,
                    onQuantityChanged: (q) => _setQuantity(context, item.id, q),
                  );
                },
              ),
            ),
      bottomNavigationBar: cart.isEmpty
          ? null
          : TotalBar(
              label: 'Subtotal (${cart.count} barang)',
              amount: cart.subtotal,
              note: 'Ongkir dihitung di checkout',
              action: 'Lanjut ke checkout',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CheckoutScreen()),
              ),
            ),
    );
  }
}
