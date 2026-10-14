import 'package:flutter_test/flutter_test.dart';

import 'package:naura_mobile/models/address.dart';
import 'package:naura_mobile/models/destination.dart';
import 'package:naura_mobile/models/shipping_rate.dart';

void main() {
  test('Address.fromJson dan toJson memakai nama field API', () {
    final json = {
      'id': 3,
      'label': 'Rumah',
      'recipient_name': 'Budi',
      'phone': '081200000003',
      'address_line': 'Jl. Merdeka 1',
      'subdistrict': 'Braga',
      'district': 'Sumur Bandung',
      'city': 'Bandung',
      'province': 'Jawa Barat',
      'postal_code': '40111',
      'destination_id': 17473,
      'is_default': true,
    };
    final a = Address.fromJson(json);

    expect(a.destinationId, 17473);
    expect(a.isDefault, isTrue);
    expect(a.areaLine, 'Braga, Sumur Bandung, Bandung, Jawa Barat 40111');
    expect(a.toJson(), {...json}..remove('id'));
  });

  test('areaLine melewati bagian yang kosong', () {
    final a = Address.fromJson({
      'id': 1, 'label': 'Kantor', 'recipient_name': 'Budi', 'phone': '0812',
      'address_line': 'Jl. A', 'subdistrict': null, 'district': null, 'city': 'Bandung',
      'province': 'Jawa Barat', 'postal_code': '40111', 'destination_id': null, 'is_default': false,
    });
    expect(a.areaLine, 'Bandung, Jawa Barat 40111');
  });

  test('Destination.fromJson membaca hasil pencarian kecamatan', () {
    final d = Destination.fromJson({
      'id': 17473, 'label': 'BRAGA, SUMUR BANDUNG', 'subdistrict': 'BRAGA', 'district': 'SUMUR BANDUNG',
      'city': 'BANDUNG', 'province': 'JAWA BARAT', 'postal_code': '40111',
    });
    expect(d.id, 17473);
    expect(d.postalCode, '40111');
  });

  test('ShippingRate menampilkan label kurir dan estimasi dalam hari', () {
    final r = ShippingRate.fromJson({
      'courier': 'jne', 'courier_name': 'JNE', 'service': 'REG', 'description': 'Reguler',
      'cost': 18000, 'etd': '2-3 day',
    });
    expect(r.label, 'JNE REG');
    expect(r.etdLabel, 'Estimasi 2–3 hari');
  });

  test('estimasi kosong atau sudah berisi "hari" ditangani', () {
    ShippingRate rate(String etd) => ShippingRate(
        courier: 'x', courierName: 'X', service: 'Y', description: '', cost: 1, etd: etd);
    expect(rate('').etdLabel, isNull);
    expect(rate('1-2 HARI').etdLabel, 'Estimasi 1–2 hari');
    expect(rate('1').etdLabel, 'Estimasi 1 hari');
  });

  test('kurir toko berlabel "Kurir toko"', () {
    const r = ShippingRate(
        courier: 'toko', courierName: 'Kurir toko', service: 'REG', description: 'Ongkir flat', cost: 15000, etd: '');
    expect(r.label, 'Kurir toko');
  });
}
