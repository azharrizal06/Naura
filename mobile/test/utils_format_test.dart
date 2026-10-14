import 'package:flutter_test/flutter_test.dart';

import 'package:naura_mobile/utils/format.dart';

void main() {
  test('titleCase merapikan nama wilayah dari RajaOngkir', () {
    expect(titleCase('SUMUR BANDUNG'), 'Sumur Bandung');
    expect(titleCase('DKI JAKARTA'), 'DKI Jakarta');
    expect(titleCase('kota  bandung'), 'Kota Bandung');
  });
}
