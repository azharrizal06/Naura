import 'package:flutter_test/flutter_test.dart';

import 'package:naura_mobile/controllers/address_controller.dart';
import 'package:naura_mobile/services/api_client.dart';

import '../fakes/fake_shipping.dart';

void main() {
  late FakeAddressService service;
  late AddressController controller;

  setUp(() {
    service = FakeAddressService();
    controller = AddressController(service);
  });

  test('load mengisi daftar dan alamat default', () async {
    service.items.addAll([address(id: 1, isDefault: false), address(id: 2, label: 'Kantor')]);
    await controller.load();
    expect(controller.addresses, hasLength(2));
    expect(controller.defaultAddress?.id, 2);
  });

  test('save tanpa id membuat alamat baru dan mengembalikannya', () async {
    final result = await controller.save(address(id: 0));
    expect(result.error, isNull);
    expect(result.address?.id, isNot(0));
    expect(controller.addresses.single.isDefault, isTrue);
  });

  test('save dengan id mengubah alamat yang ada', () async {
    final created = (await controller.save(address(id: 0))).address!;
    await controller.save(created.copyWith(label: 'Rumah Ibu'));
    expect(controller.addresses.single.label, 'Rumah Ibu');
  });

  test('alamat baru sebagai default melepas default lama', () async {
    await controller.save(address(id: 0));
    await controller.save(address(id: 0, label: 'Kantor', isDefault: true));
    expect(controller.defaultAddress?.label, 'Kantor');
    expect(controller.addresses.where((a) => a.isDefault), hasLength(1));
  });

  test('save gagal validasi mengembalikan pesan field pertama', () async {
    service.error = ApiException(422, 'Data tidak valid', errors: {
      'postal_code': ['Kode pos harus 5 angka.'],
    });
    final result = await controller.save(address(id: 0));
    expect(result.address, isNull);
    expect(result.error, 'Kode pos harus 5 angka.');
  });

  test('remove menghapus dan memuat ulang daftar', () async {
    final a = (await controller.save(address(id: 0))).address!;
    expect(await controller.remove(a.id), isNull);
    expect(controller.addresses, isEmpty);
  });
}
