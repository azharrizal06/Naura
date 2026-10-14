import 'package:naura_mobile/models/cart.dart';
import 'package:naura_mobile/models/category.dart';
import 'package:naura_mobile/models/product.dart';
import 'package:naura_mobile/models/user.dart';
import 'package:naura_mobile/services/api_client.dart';
import 'package:naura_mobile/services/auth_service.dart';
import 'package:naura_mobile/services/cart_service.dart';
import 'package:naura_mobile/services/catalog_service.dart';

ProductListItem listItem(int id) => ProductListItem(
      id: id,
      name: 'Produk $id',
      slug: 'produk-$id',
      basePrice: 100000,
      categoryName: 'Gamis',
      primaryImage: null,
    );

ProductVariant variant(int id, String name, {int stock = 5, int price = 289000}) =>
    ProductVariant(id: id, sku: 'SKU-$id', name: name, price: price, stock: stock, inStock: stock > 0);

ProductDetail detail(List<ProductVariant> variants) => ProductDetail(
      id: 1,
      name: 'Gamis Ceruti Alesha',
      slug: 'gamis-ceruti-alesha',
      description: null,
      basePrice: 289000,
      categoryName: 'Gamis',
      images: const [],
      variants: variants,
    );

/// Katalog palsu: 2 halaman berisi 2 produk, mencatat parameter terakhir.
class FakeCatalogService implements CatalogService {
  String? lastSearch;
  String? lastCategory;
  int calls = 0;
  bool fail = false;
  ProductDetail? productDetail;

  @override
  Future<ProductPage> products({String? search, String? categorySlug, int page = 1}) async {
    calls++;
    lastSearch = search;
    lastCategory = categorySlug;
    if (fail) throw ApiException(500, 'Server error');
    return ProductPage(
      items: [listItem(page * 10 + 1), listItem(page * 10 + 2)],
      currentPage: page,
      lastPage: 2,
    );
  }

  @override
  Future<List<Category>> categories() async =>
      const [Category(id: 1, name: 'Gamis', slug: 'gamis', productsCount: 2)];

  @override
  Future<ProductDetail> product(String slug) async {
    if (productDetail == null) throw ApiException(404, 'Tidak ditemukan');
    return productDetail!;
  }
}

class FakeAuthService implements AuthService {
  String? token;
  ApiException? loginError;

  static const user = User(
    id: 3,
    name: 'Budi Customer',
    email: 'customer@naura.test',
    phone: null,
    role: 'customer',
    roleLabel: 'Customer',
    isActive: true,
  );

  @override
  Future<String?> loadToken() async => token;

  @override
  Future<User> me() async => user;

  @override
  Future<AuthResult> login(String email, String password) async {
    if (loginError != null) throw loginError!;
    token = 'tok';
    return AuthResult(user, 'tok');
  }

  @override
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async =>
      AuthResult(user, 'tok');

  @override
  Future<void> logout() async => token = null;
}

/// Keranjang palsu di memori dengan aturan stok seperti API.
class FakeCartService implements CartService {
  final List<CartItem> items = [];
  int shipping = 15000;

  Cart _cart() {
    final subtotal = items.fold(0, (s, i) => s + i.lineTotal);
    return Cart(
      items: List.of(items),
      count: items.fold(0, (s, i) => s + i.quantity),
      subtotal: subtotal,
      shippingCost: items.isEmpty ? 0 : shipping,
      total: subtotal + (items.isEmpty ? 0 : shipping),
    );
  }

  @override
  Future<Cart> fetch() async => _cart();

  @override
  Future<Cart> add(int variantId, {int quantity = 1}) async {
    final i = items.indexWhere((e) => e.variantId == variantId);
    final current = i == -1 ? 0 : items[i].quantity;
    if (current + quantity > 3) {
      throw ApiException(422, 'Stok Mocca / L tinggal 3.', errors: {
        'quantity': ['Stok Mocca / L tinggal 3.'],
      });
    }
    final item = CartItem(
      id: variantId * 100,
      variantId: variantId,
      variantName: 'Mocca / L',
      productId: 1,
      productName: 'Gamis Ceruti Alesha',
      productSlug: 'gamis-ceruti-alesha',
      imageUrl: null,
      unitPrice: 289000,
      quantity: current + quantity,
      stock: 3,
    );
    if (i == -1) {
      items.add(item);
    } else {
      items[i] = item;
    }
    return _cart();
  }

  @override
  Future<Cart> update(int itemId, int quantity) async {
    final i = items.indexWhere((e) => e.id == itemId);
    items[i] = items[i].copyWith(quantity: quantity);
    return _cart();
  }

  @override
  Future<Cart> remove(int itemId) async {
    items.removeWhere((e) => e.id == itemId);
    return _cart();
  }
}
