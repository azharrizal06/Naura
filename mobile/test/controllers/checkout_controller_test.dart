import 'package:flutter_test/flutter_test.dart';

import 'package:naura_mobile/controllers/checkout_controller.dart';
import 'package:naura_mobile/services/api_client.dart';

import '../fakes/fake_shipping.dart';
import '../fakes/fake_store.dart';

void main() {
  late FakeShippingService shipping;
  late FakeStoreService store;
  late CheckoutController c;

  setUp(() {
    shipping = FakeShippingService();
    store = FakeStoreService();
    c = CheckoutController(shipping, store);
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
    c.selectBank('BSI');
    final order = c.toOrder(notes: 'Bungkus rapi');
    expect(order.addressId, 1);
    expect(order.courier, 'jnt');
    expect(order.service, 'EZ');
    expect(order.bank, 'BSI');
  });

  test('init memuat rekening dari server dan memilih yang pertama', () async {
    await c.init([address(id: 1)]);
    expect(store.calls, 1);
    expect(c.banks.map((b) => b.bank), ['BCA', 'BSI']);
    expect(c.bank, 'BCA');
  });

  test('rekening gagal dimuat → pesan error, belum siap dipesan, bisa dimuat ulang', () async {
    store.error = ApiException(500, 'Server error');
    await c.init([address(id: 1)]);
    expect(c.banksError, isNotNull);
    expect(c.bank, isNull);
    expect(c.ready, isFalse);

    store.error = null;
    await c.loadBanks();
    expect(c.banksError, isNull);
    expect(c.bank, 'BCA');
    expect(c.ready, isTrue);
  });

  test('toko belum punya rekening → tidak ada bank terpilih dan belum siap', () async {
    store.accounts = [];
    await c.init([address(id: 1)]);
    expect(c.banks, isEmpty);
    expect(c.bank, isNull);
    expect(c.ready, isFalse);
  });
}
