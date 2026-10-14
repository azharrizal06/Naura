import 'package:flutter/foundation.dart';

import '../models/cart.dart';
import '../services/api_client.dart';
import '../services/cart_service.dart';

/// Keranjang customer, disimpan di server. Aksi mengembalikan pesan error
/// (null = berhasil) supaya layar bisa menampilkannya.
class CartController extends ChangeNotifier {
  CartController(this._service);

  final CartService _service;

  Cart _cart = Cart.empty;
  bool _busy = false;

  Cart get cart => _cart;
  bool get busy => _busy;

  Future<String?> load() => _run(_service.fetch);

  Future<String?> add(int variantId, {int quantity = 1}) =>
      _run(() => _service.add(variantId, quantity: quantity));

  /// Jumlah 0 atau kurang menghapus baris.
  Future<String?> setQuantity(int itemId, int quantity) => quantity <= 0
      ? remove(itemId)
      : _run(() => _service.update(itemId, quantity));

  Future<String?> remove(int itemId) => _run(() => _service.remove(itemId));

  /// Saat logout: kosongkan tampilan; keranjang tetap tersimpan di server.
  void reset() {
    _cart = Cart.empty;
    notifyListeners();
  }

  Future<String?> _run(Future<Cart> Function() action) async {
    _busy = true;
    notifyListeners();
    try {
      _cart = await action();
      return null;
    } on ApiException catch (e) {
      final fieldErrors = e.errors?.values.firstOrNull;
      return fieldErrors is List && fieldErrors.isNotEmpty ? '${fieldErrors.first}' : e.message;
    } catch (_) {
      return 'Keranjang tidak bisa diperbarui. Periksa koneksi internet lalu coba lagi.';
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
