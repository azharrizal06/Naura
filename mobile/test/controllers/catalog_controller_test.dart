import 'package:flutter_test/flutter_test.dart';

import 'package:naura_mobile/controllers/catalog_controller.dart';

import '../fakes/fake_services.dart';

void main() {
  late FakeCatalogService service;
  late CatalogController controller;

  setUp(() {
    service = FakeCatalogService();
    controller = CatalogController(service);
  });

  test('init memuat kategori dan halaman pertama', () async {
    await controller.init();
    expect(controller.categories, hasLength(1));
    expect(controller.products.map((p) => p.id), [11, 12]);
    expect(controller.hasMore, isTrue);
  });

  test('loadMore menambahkan halaman berikutnya lalu berhenti di halaman terakhir', () async {
    await controller.init();
    await controller.loadMore();
    expect(controller.products, hasLength(4));
    expect(controller.hasMore, isFalse);

    await controller.loadMore();
    expect(service.calls, 2);
  });

  test('memilih kategori mengulang dari halaman pertama dengan filter', () async {
    await controller.init();
    await controller.loadMore();
    await controller.selectCategory('gamis');
    expect(controller.activeCategory, 'gamis');
    expect(service.lastCategory, 'gamis');
    expect(controller.products, hasLength(2));
  });

  test('pencarian kosong dikirim sebagai null', () async {
    await controller.search('  ');
    expect(service.lastSearch, isNull);
    await controller.search(' gamis ');
    expect(service.lastSearch, 'gamis');
  });

  test('gagal memuat → pesan error, tanpa produk', () async {
    service.fail = true;
    await controller.init();
    expect(controller.error, isNotNull);
    expect(controller.products, isEmpty);
    expect(controller.loading, isFalse);
  });
}
