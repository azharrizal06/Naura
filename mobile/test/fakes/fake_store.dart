import 'package:naura_mobile/models/order.dart';
import 'package:naura_mobile/services/api_client.dart';
import 'package:naura_mobile/services/store_service.dart';

const bca = (bank: 'BCA', number: '1234567890', holder: 'Toko Naura');
const bsi = (bank: 'BSI', number: '7777777777', holder: 'Toko Naura');

class FakeStoreService implements StoreService {
  List<BankAccount> accounts = [bca, bsi];
  ApiException? error;
  int calls = 0;

  @override
  Future<List<BankAccount>> bankAccounts() async {
    calls++;
    if (error != null) throw error!;
    return accounts;
  }
}
