import 'package:flutter_test/flutter_test.dart';

import 'package:naura_mobile/models/variant_options.dart';

import '../fakes/fake_services.dart';

void main() {
  final variants = [
    variant(1, 'Mocca / M'),
    variant(2, 'Mocca / L', stock: 0),
    variant(3, 'Hitam / M'),
  ];

  test('memecah "Warna / Ukuran" menjadi daftar warna dan ukuran berurutan', () {
    final o = VariantOptions(variants);
    expect(o.usesColors, isTrue);
    expect(o.colors, ['Mocca', 'Hitam']);
    expect(o.sizes, ['M', 'L']);
  });

  test('find mencari varian dari warna + ukuran', () {
    expect(VariantOptions(variants).find('Hitam', 'M')?.id, 3);
    expect(VariantOptions(variants).find('Hitam', 'L'), isNull);
  });

  test('warna tersedia bila ada satu ukuran yang masih ada stok', () {
    final o = VariantOptions([variant(1, 'Sage / M', stock: 0), variant(2, 'Taro / M')]);
    expect(o.colorAvailable('Sage'), isFalse);
    expect(o.colorAvailable('Taro'), isTrue);
  });

  test('pindah warna mempertahankan ukuran bila ada, kalau tidak pilih yang ada stok', () {
    final o = VariantOptions(variants);
    expect(o.variantForColor('Hitam', keepSize: 'M')?.id, 3);
    expect(o.variantForColor('Mocca', keepSize: 'XL')?.id, 1);
  });

  test('nama tanpa warna dikenal → bukan mode warna', () {
    expect(VariantOptions([variant(1, 'Standar')]).usesColors, isFalse);
  });
}
