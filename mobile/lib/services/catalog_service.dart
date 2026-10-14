import '../models/category.dart';
import '../models/product.dart';
import 'api_client.dart';

/// Hasil halaman produk + metadata paginasi.
class ProductPage {
  final List<ProductListItem> items;
  final int currentPage;
  final int lastPage;

  ProductPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
  });

  bool get hasMore => currentPage < lastPage;
}

class CatalogService {
  CatalogService(this._api);

  final ApiClient _api;

  Future<ProductPage> products({
    String? search,
    String? categorySlug,
    int page = 1,
  }) async {
    final data = await _api.get('/catalog/products', query: {
      'q': search,
      'category': categorySlug,
      'page': page,
      'per_page': 12,
    }) as Map<String, dynamic>;

    final items = (data['data'] as List<dynamic>)
        .map((e) => ProductListItem.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = data['meta'] as Map<String, dynamic>;

    return ProductPage(
      items: items,
      currentPage: meta['current_page'] as int,
      lastPage: meta['last_page'] as int,
    );
  }

  Future<ProductDetail> product(String slug) async {
    final data = await _api.get('/catalog/products/$slug') as Map<String, dynamic>;
    return ProductDetail.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<List<Category>> categories() async {
    final data = await _api.get('/catalog/categories') as Map<String, dynamic>;
    return (data['data'] as List<dynamic>)
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
