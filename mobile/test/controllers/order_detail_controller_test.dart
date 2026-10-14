import 'package:flutter_test/flutter_test.dart';

import 'package:naura_mobile/controllers/order_detail_controller.dart';
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
}
