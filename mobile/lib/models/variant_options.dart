import '../utils/swatch.dart';
import 'product.dart';

/// Pilihan varian dari nama "Warna / Ukuran": daftar warna, ukuran, dan
/// pencarian varian untuk kombinasinya.
class VariantOptions {
  VariantOptions(this.variants) {
    for (final v in variants) {
      final (color, size) = splitVariant(v.name);
      if (!colors.contains(color)) colors.add(color);
      if (size != null && !sizes.contains(size)) sizes.add(size);
    }
  }

  final List<ProductVariant> variants;
  final List<String> colors = [];
  final List<String> sizes = [];

  /// Semua varian punya warna yang dikenal → tampilkan sebagai swatch.
  bool get usesColors =>
      variants.isNotEmpty && variants.every((v) => swatchFor(splitVariant(v.name).$1) != null);

  ProductVariant? find(String color, String? size) =>
      variants.where((v) => splitVariant(v.name) == (color, size)).firstOrNull;

  bool colorAvailable(String color) =>
      variants.any((v) => splitVariant(v.name).$1 == color && v.inStock);

  /// Varian untuk warna baru: ukuran yang sama bila ada, lalu yang ada stok,
  /// lalu varian pertama warna itu.
  ProductVariant? variantForColor(String color, {String? keepSize}) {
    final ofColor = variants.where((v) => splitVariant(v.name).$1 == color);
    return find(color, keepSize) ??
        ofColor.where((v) => v.inStock).firstOrNull ??
        ofColor.firstOrNull;
  }
}
