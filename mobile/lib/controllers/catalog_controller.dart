import 'package:flutter/foundation.dart' show ChangeNotifier;

import '../models/category.dart';
import '../models/product.dart';
import '../services/catalog_service.dart';

/// Katalog: kategori, pencarian, dan daftar produk berhalaman.
class CatalogController extends ChangeNotifier {
  CatalogController(this._service);

  final CatalogService _service;

  final List<ProductListItem> _products = [];
  List<Category> _categories = [];
  String? _activeCategory;
  String? _search;
  int _currentPage = 0;
  int _lastPage = 1;
  bool _loading = false;
  String? _error;

  List<ProductListItem> get products => List.unmodifiable(_products);
  List<Category> get categories => _categories;
  String? get activeCategory => _activeCategory;
  bool get isFiltered => _search != null || _activeCategory != null;
  bool get hasMore => _currentPage < _lastPage;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> init() async {
    await Future.wait([_loadCategories(), refresh()]);
  }

  /// Ulang dari halaman pertama dengan filter yang aktif.
  Future<void> refresh() async {
    _products.clear();
    _currentPage = 0;
    _lastPage = 1;
    _error = null;
    await loadMore();
  }

  Future<void> loadMore() async {
    if (_loading || !hasMore) return;
    _loading = true;
    notifyListeners();
    try {
      final page = await _service.products(
        search: _search,
        categorySlug: _activeCategory,
        page: _currentPage + 1,
      );
      _products.addAll(page.items);
      _currentPage = page.currentPage;
      _lastPage = page.lastPage;
    } catch (_) {
      _error = 'Katalog tidak bisa dimuat. Periksa koneksi internet lalu muat ulang.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> selectCategory(String? slug) {
    _activeCategory = slug;
    return refresh();
  }

  Future<void> search(String text) {
    final q = text.trim();
    _search = q.isEmpty ? null : q;
    return refresh();
  }

  Future<void> _loadCategories() async {
    try {
      _categories = await _service.categories();
      notifyListeners();
    } catch (_) {
      // Kategori opsional; katalog tetap bisa dipakai tanpa tab.
    }
  }
}
