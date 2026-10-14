import 'package:flutter_test/flutter_test.dart';

import 'package:naura_mobile/controllers/checkout_controller.dart';
import 'package:naura_mobile/services/api_client.dart';

import '../fakes/fake_shipping.dart';

void main() {
  late FakeShippingService shipping;
  late CheckoutController c;

  setUp(() {
    shipping = FakeShippingService();
    c = CheckoutController(shipping);
  });

  test('init memilih alamat default lalu memuat tarif dan memilih yang termurah', () async {
    await c.init([address(id: 1, isDefault: false), address(id: 2)]);
    expect(c.address?.id, 2);
    expect(shipping.rateRequests, [2]);
    expect(c.rates, hasLength(2));
    expect(c.rate?.courier, 'jnt');
  });

  test('tanpa alamat tidak memuat tarif', () async {
    await c.init([]);
    expect(c.address, isNull);
    expect(shipping.rateRequests, isEmpty);
  });

  test('ganti alamat memuat ulang tarif', () async {
    await c.init([address(id: 1)]);
    await c.selectAddress(address(id: 5, label: 'Kantor'));
    expect(c.address?.id, 5);
    expect(shipping.rateRequests, [1, 5]);
  });

  test('tarif gagal → pesan dari server dan tidak ada kurir terpilih', () async {
    shipping.ratesError = ApiException(422, 'x', errors: {
      'address_id': ['Pilih kecamatan dari pencarian.'],
    });
    await c.init([address(id: 1)]);
    expect(c.ratesError, 'Pilih kecamatan dari pencarian.');
    expect(c.rate, isNull);
  });

  test('total = subtotal + ongkir kurir terpilih', () async {
    await c.init([address(id: 1)]);
    c.selectRate(jneReg);
    expect(c.shippingCost, 18000);
    expect(c.totalFor(578000), 596000);
  });

  test('siap dipesan hanya bila alamat dan kurir sudah dipilih', () async {
    expect(c.ready, isFalse);
    await c.init([address(id: 1)]);
    expect(c.ready, isTrue);
  });

  test('toOrder membawa id alamat, kurir, layanan, bank, catatan', () async {
    await c.init([address(id: 1)]);
    c.selectBank('Mandiri');
    final order = c.toOrder(notes: 'Bungkus rapi');
    expect(order.addressId, 1);
    expect(order.courier, 'jnt');
    expect(order.service, 'EZ');
    expect(order.bank, 'Mandiri');
  });
}
