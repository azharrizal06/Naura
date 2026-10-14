import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/nav_controller.dart';
import '../controllers/orders_controller.dart';
import '../theme/naura_theme.dart';
import '../widgets/message_state.dart';
import '../widgets/order_row.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OrdersController>();
    final orders = controller.orders;

    final Widget body;
    if (controller.loading && orders.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (controller.error != null && orders.isEmpty) {
      body = MessageState(
        message: controller.error!,
        actionLabel: 'Muat ulang',
        onAction: controller.load,
      );
    } else if (orders.isEmpty) {
      body = MessageState(
        title: 'Belum ada pesanan',
        message: 'Pesanan yang Anda buat dari keranjang akan muncul di sini beserta statusnya.',
        actionLabel: 'Lihat koleksi',
        onAction: () => context.read<NavController>().go(NavTab.catalog),
      );
    } else {
      body = RefreshIndicator(
        onRefresh: controller.load,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          itemCount: orders.length,
          separatorBuilder: (_, _) => const Divider(height: 1, color: NauraColors.garis),
          itemBuilder: (_, i) => OrderRow(
            order: orders[i],
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => OrderDetailScreen(id: orders[i].id, initial: orders[i]),
            )),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Pesanan'), automaticallyImplyLeading: false),
      body: body,
    );
  }
}
