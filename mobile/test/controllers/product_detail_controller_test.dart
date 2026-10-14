import 'package:flutter_test/flutter_test.dart';

import 'package:naura_mobile/controllers/product_detail_controller.dart';

import '../fakes/fake_services.dart';

void main() {
  test('memilih varian pertama yang masih ada stok', () async {
    final service = FakeCatalogService()
      ..productDetail = detail([variant(1, 'Mocca / M', stock: 0), variant(2, 'Mocca / L')]);
    final c = ProductDetailController(service);

    await c.load('gamis-ceruti-alesha');

    expect(c.product?.name, 'Gamis Ceruti Alesha');
    expect(c.selected?.id, 2);
    expect(c.loading, isFalse);
  });

  test('produk tidak ditemukan → pesan error', () async {
    final c = ProductDetailController(FakeCatalogService());
    await c.load('tidak-ada');
    expect(c.product, isNull);
    expect(c.error, isNotNull);
  });

  test('select mengganti varian terpilih', () async {
    final service = FakeCatalogService()
      ..productDetail = detail([variant(1, 'Mocca / M'), variant(2, 'Hitam / M')]);
    final c = ProductDetailController(service);
    await c.load('x');

    c.select(c.product!.variants[1]);
    expect(c.selected?.id, 2);
  });
}
