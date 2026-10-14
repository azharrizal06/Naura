import 'package:flutter/foundation.dart';

import '../models/address.dart';
import '../models/order.dart';
import '../models/shipping_rate.dart';
import '../services/api_error.dart';
import '../services/shipping_service.dart';

/// Rekening transfer toko — sama dengan `store_settings.bank_accounts` di seeder.
/// Ambil dari API pengaturan toko saat endpoint-nya tersedia.
const bankAccounts = [
  (bank: 'BCA', number: '1234567890', holder: 'Toko Naura'),
  (bank: 'Mandiri', number: '0987654321', holder: 'Toko Naura'),
];

/// Pilihan di layar checkout: alamat, kurir, dan rekening tujuan.
class CheckoutController extends ChangeNotifier {
  CheckoutController(this._shipping);

  final ShippingService _shipping;

  Address? _address;
  List<ShippingRate> _rates = [];
  ShippingRate? _rate;
  bool _loadingRates = false;
  String? _ratesError;
  String _bank = bankAccounts.first.bank;

  Address? get address => _address;
  List<ShippingRate> get rates => _rates;
  ShippingRate? get rate => _rate;
  bool get loadingRates => _loadingRates;
  String? get ratesError => _ratesError;
  String get bank => _bank;

  int get shippingCost => _rate?.cost ?? 0;
  int totalFor(int subtotal) => subtotal + shippingCost;
  bool get ready => _address != null && _rate != null;

  /// Pilih alamat default dari daftar lalu hitung ongkirnya.
  Future<void> init(List<Address> addresses) async {
    final initial = addresses.where((a) => a.isDefault).firstOrNull ?? addresses.firstOrNull;
    if (initial == null) {
      _address = null;
      notifyListeners();
      return;
    }
    await selectAddress(initial);
  }

  Future<void> selectAddress(Address address) async {
    _address = address;
    await loadRates();
  }

  Future<void> loadRates() async {
    final address = _address;
    if (address == null) return;
    _loadingRates = true;
    _ratesError = null;
    _rate = null;
    _rates = [];
    notifyListeners();
    try {
      _rates = await _shipping.rates(address.id);
      // Pilihan awal: layanan termurah.
      _rate = _rates.isEmpty ? null : _rates.reduce((a, b) => b.cost < a.cost ? b : a);
    } catch (e) {
      _ratesError = apiErrorMessage(e, fallback: 'Ongkir tidak bisa dihitung saat ini. Coba lagi beberapa saat lagi.');
    } finally {
      _loadingRates = false;
      notifyListeners();
    }
  }

  void selectRate(ShippingRate rate) {
    _rate = rate;
    notifyListeners();
  }

  void selectBank(String bank) {
    _bank = bank;
    notifyListeners();
  }

  PlaceOrder toOrder({required String notes}) => PlaceOrder(
        addressId: _address!.id,
        courier: _rate!.courier,
        service: _rate!.service,
        bank: _bank,
        notes: notes,
      );
}
