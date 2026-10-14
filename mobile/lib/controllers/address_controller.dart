import 'package:flutter/foundation.dart';

import '../models/address.dart';
import '../services/address_service.dart';
import '../services/api_error.dart';

typedef SaveAddressResult = ({Address? address, String? error});

/// Alamat pengiriman tersimpan milik customer.
class AddressController extends ChangeNotifier {
  AddressController(this._service);

  final AddressService _service;

  List<Address> _addresses = [];
  bool _loading = false;
  bool _saving = false;
  String? _error;

  List<Address> get addresses => _addresses;
  bool get loading => _loading;
  bool get saving => _saving;
  String? get error => _error;

  Address? get defaultAddress =>
      _addresses.where((a) => a.isDefault).firstOrNull ?? _addresses.firstOrNull;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _addresses = await _service.list();
    } catch (e) {
      _error = apiErrorMessage(e, fallback: 'Alamat tidak bisa dimuat. Periksa koneksi internet lalu coba lagi.');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Buat alamat baru (id 0) atau ubah yang sudah ada.
  Future<SaveAddressResult> save(Address draft) async {
    _saving = true;
    notifyListeners();
    try {
      final saved = draft.id == 0 ? await _service.create(draft) : await _service.update(draft);
      _addresses = await _service.list();
      return (address: saved, error: null);
    } catch (e) {
      return (
        address: null,
        error: apiErrorMessage(e, fallback: 'Alamat tidak tersimpan. Periksa koneksi internet lalu coba lagi.'),
      );
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<String?> remove(int id) async {
    try {
      await _service.delete(id);
      _addresses = await _service.list();
      notifyListeners();
      return null;
    } catch (e) {
      return apiErrorMessage(e, fallback: 'Alamat tidak terhapus. Periksa koneksi internet lalu coba lagi.');
    }
  }

  void reset() {
    _addresses = [];
    notifyListeners();
  }
}
