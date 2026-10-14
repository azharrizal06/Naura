import 'package:flutter/foundation.dart';

import '../models/product.dart';
import '../services/catalog_service.dart';

/// Detail satu produk dan varian yang sedang dipilih.
class ProductDetailController extends ChangeNotifier {
  ProductDetailController(this._service);

  final CatalogService _service;

  ProductDetail? _product;
  ProductVariant? _selected;
  bool _loading = true;
  String? _error;

  ProductDetail? get product => _product;
  ProductVariant? get selected => _selected;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load(String slug) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final product = await _service.product(slug);
      _product = product;
      _selected = product.variants.where((v) => v.inStock).firstOrNull ??
          product.variants.firstOrNull;
    } catch (_) {
      _error = 'Produk ini tidak bisa dimuat. Kembali lalu coba buka lagi.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void select(ProductVariant variant) {
    _selected = variant;
    notifyListeners();
  }
}
