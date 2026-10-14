import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/address_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/cart_controller.dart';
import '../controllers/nav_controller.dart';
import '../controllers/orders_controller.dart';
import '../theme/naura_theme.dart';
import 'addresses_screen.dart';
import 'change_password_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

/// Akun: data diri, alamat pengiriman, ubah profil, ganti password, dan keluar.
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
          _MenuTile(
            icon: Icons.person_outline,
            title: 'Ubah profil',
            subtitle: 'Nama, nomor HP, dan email',
            builder: (_) => const ProfileScreen(),
          ),
          const Divider(height: 1, color: NauraColors.garis),
          _MenuTile(
            icon: Icons.lock_outline,
            title: 'Ganti password',
            subtitle: 'Perangkat lain akan dikeluarkan',
            builder: (_) => const ChangePasswordScreen(),
          ),
          const Divider(height: 1, color: NauraColors.garis),
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

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.icon, required this.title, required this.subtitle, required this.builder});

  final IconData icon;
  final String title;
  final String subtitle;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: NauraColors.plum),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right, color: NauraColors.muted),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: builder)),
    );
  }
}
