import 'package:flutter_test/flutter_test.dart';

import 'package:naura_mobile/controllers/orders_controller.dart';
import 'package:naura_mobile/models/order.dart';
import 'package:naura_mobile/services/api_client.dart';

import '../fakes/fake_orders.dart';

const _request = PlaceOrder(addressId: 4, courier: 'jne', service: 'REG', bank: 'BCA', notes: '');

void main() {
  test('load mengisi daftar pesanan', () async {
    final c = OrdersController(FakeOrderService());
    await c.load();
    expect(c.orders.map((o) => o.id), [2, 1]);
    expect(c.loading, isFalse);
    expect(c.error, isNull);
  });

  test('load gagal → pesan error', () async {
    final c = OrdersController(FakeOrderService()..error = ApiException(500, 'Server error'));
    await c.load();
    expect(c.orders, isEmpty);
    expect(c.error, isNotNull);
  });

  test('place berhasil mengembalikan pesanan baru dan menaruhnya paling atas', () async {
    final service = FakeOrderService();
    final c = OrdersController(service);
    final result = await c.place(_request);

    expect(result.order?.id, 9);
    expect(result.error, isNull);
    expect(service.lastPlaced?.bank, 'BCA');
    expect(c.orders.first.id, 9);
  });

  test('place ditolak (422) mengembalikan pesan field pertama dari server', () async {
    final c = OrdersController(FakeOrderService()
      ..error = ApiException(422, 'Data tidak valid', errors: {
        'cart': ['Keranjang kosong.'],
      }));
    final result = await c.place(_request);
    expect(result.order, isNull);
    expect(result.error, 'Keranjang kosong.');
  });

  test('endpoint belum ada (404) → pesan jelas, bukan pesan teknis', () async {
    final c = OrdersController(
        FakeOrderService()..error = ApiException(404, 'The route api/orders could not be found.'));
    final result = await c.place(_request);
    expect(result.error, 'Pembuatan pesanan belum tersedia. Keranjang Anda tetap tersimpan.');
  });

  test('replace memperbarui pesanan di daftar (mis. setelah dibatalkan)', () async {
    final c = OrdersController(FakeOrderService());
    await c.load();
    c.replace(Order.fromJson(orderJson(id: 2, status: 'cancelled')));
    expect(c.orders.map((o) => o.id), [2, 1]);
    expect(c.orders.first.status, OrderStatus.cancelled);
  });
}
