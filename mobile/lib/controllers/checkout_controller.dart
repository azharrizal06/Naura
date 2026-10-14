import 'package:flutter/foundation.dart';

import '../models/address.dart';
import '../models/order.dart';
import '../models/shipping_rate.dart';
import '../services/api_error.dart';
import '../services/shipping_service.dart';
import '../services/store_service.dart';

/// Pilihan di layar checkout: alamat, kurir, dan rekening tujuan.
class CheckoutController extends ChangeNotifier {
  CheckoutController(this._shipping, this._store);

  final ShippingService _shipping;
  final StoreService _store;

  Address? _address;
  List<ShippingRate> _rates = [];
  ShippingRate? _rate;
  bool _loadingRates = false;
  String? _ratesError;
  List<BankAccount> _banks = [];
  bool _loadingBanks = false;
  String? _banksError;
  String? _bank;

  Address? get address => _address;
  List<ShippingRate> get rates => _rates;
  ShippingRate? get rate => _rate;
  bool get loadingRates => _loadingRates;
  String? get ratesError => _ratesError;
  List<BankAccount> get banks => _banks;
  bool get loadingBanks => _loadingBanks;
  String? get banksError => _banksError;
  String? get bank => _bank;

  int get shippingCost => _rate?.cost ?? 0;
  int totalFor(int subtotal) => subtotal + shippingCost;
  bool get ready => _address != null && _rate != null && _bank != null;

  /// Muat rekening toko, pilih alamat default, lalu hitung ongkirnya.
  Future<void> init(List<Address> addresses) async {
    final banks = loadBanks();
    final initial = addresses.where((a) => a.isDefault).firstOrNull ?? addresses.firstOrNull;
    if (initial == null) {
      _address = null;
      notifyListeners();
    } else {
      await selectAddress(initial);
    }
    await banks;
  }

  /// Rekening tujuan transfer dari `store_settings.bank_accounts`.
  Future<void> loadBanks() async {
    _loadingBanks = true;
    _banksError = null;
    notifyListeners();
    try {
      _banks = await _store.bankAccounts();
      if (!_banks.any((b) => b.bank == _bank)) _bank = _banks.firstOrNull?.bank;
    } catch (e) {
      _banks = [];
      _bank = null;
      _banksError = apiErrorMessage(e, fallback: 'Rekening toko tidak bisa dimuat. Coba lagi.');
    } finally {
      _loadingBanks = false;
      notifyListeners();
    }
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
        bank: _bank!,
        notes: notes,
      );
}
