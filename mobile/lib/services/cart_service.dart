import '../models/cart.dart';
import 'api_client.dart';

/// Endpoint keranjang customer (`/api/cart`).
class CartService {
  CartService(this._api);

  final ApiClient _api;

  Future<Cart> fetch() async => _parse(await _api.get('/cart'));

  Future<Cart> add(int variantId, {int quantity = 1}) async => _parse(
      await _api.post('/cart/items', body: {'variant_id': variantId, 'quantity': quantity}));

  Future<Cart> update(int itemId, int quantity) async =>
      _parse(await _api.patch('/cart/items/$itemId', body: {'quantity': quantity}));

  Future<Cart> remove(int itemId) async => _parse(await _api.delete('/cart/items/$itemId'));

  Cart _parse(dynamic res) =>
      Cart.fromJson((res as Map<String, dynamic>)['data'] as Map<String, dynamic>);
}
