import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/address_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/cart_controller.dart';
import '../controllers/nav_controller.dart';
import '../controllers/orders_controller.dart';
import '../theme/naura_theme.dart';
import 'addresses_screen.dart';
import 'login_screen.dart';

/// Akun: data diri, alamat pengiriman, dan keluar. Ubah profil menyusul (Fase 7).
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final cart = context.read<CartController>();
    final orders = context.read<OrdersController>();
    final addresses = context.read<AddressController>();
    final nav = context.read<NavController>();
    await context.read<AuthController>().logout();
    cart.reset();
    orders.reset();
    addresses.reset();
    nav.go(NavTab.catalog);
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user;
    final addressCount = context.watch<AddressController>().addresses.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Akun'), automaticallyImplyLeading: false),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(user?.name ?? '', style: display(28)),
          const SizedBox(height: 6),
          Text(user?.email ?? '', style: const TextStyle(color: NauraColors.muted)),
          if (user?.phone != null)
            Text(user!.phone!, style: const TextStyle(color: NauraColors.muted)),
          const SizedBox(height: 28),
          const Divider(height: 1, color: NauraColors.garis),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.place_outlined, color: NauraColors.plum),
            title: const Text('Alamat pengiriman', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(addressCount == 0 ? 'Belum ada alamat tersimpan' : '$addressCount alamat tersimpan'),
            trailing: const Icon(Icons.chevron_right, color: NauraColors.muted),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AddressesScreen()),
            ),
          ),
          const Divider(height: 1, color: NauraColors.garis),
          const SizedBox(height: 16),
          const Text(
            'Ubah nama, email, dan password akan tersedia di pembaruan berikutnya.',
            style: TextStyle(fontSize: 13, color: NauraColors.muted, height: 1.5),
          ),
          const SizedBox(height: 28),
          OutlinedButton(
            onPressed: () => _logout(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: NauraColors.marun,
              side: const BorderSide(color: NauraColors.garisKuat),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}
