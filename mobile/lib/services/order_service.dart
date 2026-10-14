import '../models/order.dart';
import 'api_client.dart';

/// Endpoint pesanan customer (`/api/orders`) — kontrak Fase 4.
class OrderService {
  OrderService(this._api);

  final ApiClient _api;

  Future<List<Order>> list() async {
    final res = await _api.get('/orders') as Map<String, dynamic>;
    return (res['data'] as List<dynamic>)
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Order> find(int id) async => _parse(await _api.get('/orders/$id'));

  Future<Order> place(PlaceOrder request) async =>
      _parse(await _api.post('/orders', body: request.toJson()));

  /// Batalkan pesanan yang belum dibayar; server mengembalikan stoknya.
  Future<Order> cancel(int id) async => _parse(await _api.post('/orders/$id/cancel'));

  /// Tandai paket yang sedang dikirim sudah diterima.
  Future<Order> complete(int id) async => _parse(await _api.post('/orders/$id/complete'));

  Order _parse(dynamic res) =>
      Order.fromJson((res as Map<String, dynamic>)['data'] as Map<String, dynamic>);
}
