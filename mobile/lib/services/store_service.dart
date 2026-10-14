import '../models/order.dart';
import 'api_client.dart';

/// Info toko dari `GET /store` (publik).
class StoreService {
  StoreService(this._api);

  final ApiClient _api;

  /// Rekening tujuan transfer — sumbernya `store_settings.bank_accounts`.
  Future<List<BankAccount>> bankAccounts() async {
    final res = await _api.get('/store') as Map<String, dynamic>;
    final data = res['data'] as Map<String, dynamic>;
    return (data['bank_accounts'] as List<dynamic>).map((e) {
      final m = e as Map<String, dynamic>;
      return (bank: m['bank'] as String, number: m['number'] as String, holder: m['holder'] as String);
    }).toList();
  }
}
