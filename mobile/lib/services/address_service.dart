import '../models/address.dart';
import 'api_client.dart';

/// Endpoint alamat tersimpan (`/api/addresses`).
class AddressService {
  AddressService(this._api);

  final ApiClient _api;

  Future<List<Address>> list() async {
    final res = await _api.get('/addresses') as Map<String, dynamic>;
    return (res['data'] as List<dynamic>)
        .map((e) => Address.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Address> create(Address draft) async =>
      _parse(await _api.post('/addresses', body: draft.toJson()));

  Future<Address> update(Address address) async =>
      _parse(await _api.patch('/addresses/${address.id}', body: address.toJson()));

  Future<void> delete(int id) => _api.delete('/addresses/$id');

  Address _parse(dynamic res) =>
      Address.fromJson((res as Map<String, dynamic>)['data'] as Map<String, dynamic>);
}
