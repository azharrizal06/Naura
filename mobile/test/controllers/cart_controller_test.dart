import 'package:flutter_test/flutter_test.dart';

import 'package:naura_mobile/controllers/cart_controller.dart';

import '../fakes/fake_services.dart';

void main() {
  late FakeCartService service;
  late CartController cart;

  setUp(() {
    service = FakeCartService();
    cart = CartController(service);
  });

  test('add menyimpan keranjang dari server dan mengembalikan null bila berhasil', () async {
    final error = await cart.add(5);
    expect(error, isNull);
    expect(cart.cart.count, 1);
    expect(cart.cart.total, 289000 + 15000);
  });

  test('add yang ditolak stok mengembalikan pesan server dan keranjang tidak berubah', () async {
    await cart.add(5, quantity: 3);
    final error = await cart.add(5);
    expect(error, 'Stok Mocca / L tinggal 3.');
    expect(cart.cart.count, 3);
  });

  test('setQuantity dan remove memakai id baris', () async {
    await cart.add(5);
    final id = cart.cart.items.single.id;

    await cart.setQuantity(id, 2);
    expect(cart.cart.count, 2);

    await cart.remove(id);
    expect(cart.cart.isEmpty, isTrue);
  });

  test('setQuantity 0 menghapus baris', () async {
    await cart.add(5);
    await cart.setQuantity(cart.cart.items.single.id, 0);
    expect(cart.cart.isEmpty, isTrue);
  });

  test('load mengambil keranjang tersimpan; reset mengosongkan tampilan lokal', () async {
    await service.add(5, quantity: 2);
    await cart.load();
    expect(cart.cart.count, 2);

    cart.reset();
    expect(cart.cart.isEmpty, isTrue);
  });
}
