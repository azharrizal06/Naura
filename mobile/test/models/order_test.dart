import 'package:flutter_test/flutter_test.dart';

import 'package:naura_mobile/models/order.dart';

import '../fakes/fake_orders.dart';

void main() {
  test('Order.fromJson membaca pesanan lengkap', () {
    final order = Order.fromJson(orderJson(status: 'shipped'));

    expect(order.orderNumber, 'INV-20261013-0001');
    expect(order.status, OrderStatus.shipped);
    expect(order.items.single.variantName, 'Mocca / L');
    expect(order.items.single.subtotal, 578000);
    expect(order.address.city, 'Bandung');
    expect(order.payment?.bank?.number, '1234567890');
    expect(order.shipment?.trackingNumber, 'JNE123');
    expect(order.total, 593000);
    expect(order.itemCount, 2);
  });

  test('status punya urutan langkah; dibatalkan tidak ada di urutan', () {
    expect(OrderStatus.steps.first, OrderStatus.pending);
    expect(OrderStatus.steps.last, OrderStatus.completed);
    expect(OrderStatus.shipped.step, 3);
    expect(OrderStatus.cancelled.step, -1);
  });

  test('status tak dikenal dibaca sebagai menunggu pembayaran', () {
    expect(OrderStatus.parse('aneh'), OrderStatus.pending);
  });

  test('PlaceOrder.toJson memakai alamat tersimpan dan layanan kurir', () {
    const req = PlaceOrder(addressId: 4, courier: 'jne', service: 'REG', bank: 'BCA', notes: ' ');
    expect(req.toJson(), {
      'address_id': 4,
      'courier': 'jne',
      'service': 'REG',
      'payment_method': 'manual_transfer',
      'bank': 'BCA',
      'notes': null,
    });
  });

  test('Shipment membaca layanan dan label kurir', () {
    final order = Order.fromJson(orderJson(status: 'pending'));
    expect(order.shipment?.service, 'REG');
    expect(order.shipment?.courierLabel, 'JNE REG');
  });
}
