import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/address_controller.dart';
import '../controllers/cart_controller.dart';
import '../controllers/catalog_controller.dart';
import '../controllers/nav_controller.dart';
import '../controllers/orders_controller.dart';
import '../theme/naura_theme.dart';
import 'account_screen.dart';
import 'cart_screen.dart';
import 'home_screen.dart';
import 'orders_screen.dart';

/// Kerangka setelah login: empat tab dengan navigasi bawah.
/// Tiap tab mempertahankan posisi gulir saat berpindah.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  @override
  void initState() {
    super.initState();
    final catalog = context.read<CatalogController>();
    if (catalog.products.isEmpty) catalog.init();
    context.read<CartController>().load();
    context.read<OrdersController>().load();
    context.read<AddressController>().load();
  }

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavController>();
    final cartCount = context.select<CartController, int>((c) => c.cart.count);

    return Scaffold(
      body: IndexedStack(
        index: nav.tab.index,
        children: const [HomeScreen(), CartScreen(), OrdersScreen(), AccountScreen()],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: NauraColors.garis)),
        ),
        child: NavigationBar(
          selectedIndex: nav.tab.index,
          onDestinationSelected: (i) => nav.go(NavTab.values[i]),
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view_rounded),
              label: 'Koleksi',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: cartCount > 0,
                label: Text('$cartCount'),
                backgroundColor: NauraColors.plum,
                child: const Icon(Icons.shopping_bag_outlined),
              ),
              selectedIcon: Badge(
                isLabelVisible: cartCount > 0,
                label: Text('$cartCount'),
                backgroundColor: NauraColors.plum,
                child: const Icon(Icons.shopping_bag),
              ),
              label: 'Keranjang',
              tooltip: cartCount == 0 ? 'Keranjang' : 'Keranjang, $cartCount barang',
            ),
            const NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Pesanan',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Akun',
            ),
          ],
        ),
      ),
    );
  }
}
