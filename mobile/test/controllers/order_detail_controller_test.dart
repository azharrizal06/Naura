import 'package:flutter_test/flutter_test.dart';

import 'package:naura_mobile/controllers/order_detail_controller.dart';
import 'package:naura_mobile/models/order.dart';
import 'package:naura_mobile/services/api_client.dart';

import '../fakes/fake_orders.dart';

void main() {
  test('load mengambil detail pesanan', () async {
    final c = OrderDetailController(FakeOrderService());
    await c.load(4);
    expect(c.order?.id, 4);
    expect(c.loading, isFalse);
  });

  test('pesanan yang sudah dimuat bisa ditampilkan tanpa menunggu', () {
    final c = OrderDetailController(FakeOrderService(), initial: null);
    expect(c.loading, isTrue);
  });

  test('load gagal → pesan error', () async {
    final c = OrderDetailController(FakeOrderService()..error = ApiException(404, 'x'));
    await c.load(4);
    expect(c.order, isNull);
    expect(c.error, isNotNull);
  });

  test('cancel membatalkan pesanan menunggu pembayaran', () async {
    final service = FakeOrderService();
    final c = OrderDetailController(service);
    await c.load(4);
    expect(c.canCancel, isTrue);

    final error = await c.cancel();

    expect(error, isNull);
    expect(service.cancelled, [4]);
    expect(c.order?.status, OrderStatus.cancelled);
    expect(c.canCancel, isFalse);
    expect(c.busy, isFalse);
  });

  test('pesanan yang sudah dibayar tidak bisa dibatalkan', () {
    final c = OrderDetailController(FakeOrderService(),
        initial: Order.fromJson(orderJson(id: 4, status: 'paid')));
    expect(c.canCancel, isFalse);
  });

  test('cancel ditolak server (422) → pesan dari server, pesanan tidak berubah', () async {
    final service = FakeOrderService();
    final c = OrderDetailController(service);
    await c.load(4);
    service.error = ApiException(422, 'x', errors: {
      'order': ['Pesanan ini tidak bisa dibatalkan karena sudah diproses.'],
    });

    final error = await c.cancel();

    expect(error, 'Pesanan ini tidak bisa dibatalkan karena sudah diproses.');
    expect(c.order?.status, OrderStatus.pending);
    expect(c.busy, isFalse);
  });

  test('pesanan dikirim bisa ditandai diterima', () async {
    final service = FakeOrderService();
    final c = OrderDetailController(service, initial: Order.fromJson(orderJson(id: 4, status: 'shipped')));
    expect(c.canComplete, isTrue);
    expect(c.canCancel, isFalse);

    final error = await c.complete();

    expect(error, isNull);
    expect(service.completed, [4]);
    expect(c.order?.status, OrderStatus.completed);
    expect(c.canComplete, isFalse);
    expect(c.busy, isFalse);
  });

  test('pesanan yang belum dikirim tidak bisa ditandai diterima', () {
    final c = OrderDetailController(FakeOrderService(),
        initial: Order.fromJson(orderJson(id: 4, status: 'processing')));
    expect(c.canComplete, isFalse);
  });

  test('complete gagal → pesan error, status tidak berubah', () async {
    final service = FakeOrderService()..error = ApiException(422, 'x', errors: {
      'order': ['Hanya pesanan yang sedang dikirim yang bisa diselesaikan.'],
    });
    final c = OrderDetailController(service, initial: Order.fromJson(orderJson(id: 4, status: 'shipped')));

    final error = await c.complete();

    expect(error, 'Hanya pesanan yang sedang dikirim yang bisa diselesaikan.');
    expect(c.order?.status, OrderStatus.shipped);
  });
}
