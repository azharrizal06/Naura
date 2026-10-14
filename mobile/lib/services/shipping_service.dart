import '../models/destination.dart';
import '../models/shipping_rate.dart';
import 'api_client.dart';

/// Pencarian kecamatan & tarif kurir (RajaOngkir lewat backend).
class ShippingService {
  ShippingService(this._api);

  final ApiClient _api;

  Future<List<Destination>> searchDestinations(String query) async {
    final res = await _api.get('/shipping/destinations', query: {'search': query}) as Map<String, dynamic>;
    return (res['data'] as List<dynamic>)
        .map((e) => Destination.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ShippingRate>> rates(int addressId) async {
    final res = await _api.post('/shipping/rates', body: {'address_id': addressId}) as Map<String, dynamic>;
    return (res['data'] as List<dynamic>)
        .map((e) => ShippingRate.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
