import 'package:flutter_test/flutter_test.dart';

import 'package:naura_mobile/controllers/destination_search_controller.dart';
import 'package:naura_mobile/services/api_client.dart';

import '../fakes/fake_shipping.dart';

void main() {
  test('kurang dari 3 huruf tidak memanggil server', () async {
    final service = FakeShippingService();
    final c = DestinationSearchController(service);
    await c.search('br');
    expect(service.searches, isEmpty);
    expect(c.results, isEmpty);
  });

  test('pencarian mengisi hasil', () async {
    final c = DestinationSearchController(FakeShippingService());
    await c.search('braga');
    expect(c.results.single.id, 17473);
    expect(c.unavailable, isFalse);
  });

  test('server tanpa RajaOngkir (503) → mode isi manual', () async {
    final service = FakeShippingService()..searchError = ApiException(503, 'Belum tersedia');
    final c = DestinationSearchController(service);
    await c.search('braga');
    expect(c.unavailable, isTrue);
    expect(c.results, isEmpty);
  });

  test('error lain → pesan error, bukan mode manual', () async {
    final service = FakeShippingService()..searchError = ApiException(500, 'x');
    final c = DestinationSearchController(service);
    await c.search('braga');
    expect(c.unavailable, isFalse);
    expect(c.error, isNotNull);
  });
}
