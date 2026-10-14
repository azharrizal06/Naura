import 'package:flutter/foundation.dart';

import '../models/order.dart';
import '../services/api_client.dart';
import '../services/order_service.dart';

/// Hasil membuat pesanan: pesanan baru, atau pesan error.
typedef PlaceResult = ({Order? order, String? error});

/// Daftar pesanan customer dan pembuatan pesanan dari checkout.
class OrdersController extends ChangeNotifier {
  OrdersController(this._service);

  final OrderService _service;

  List<Order> _orders = [];
  bool _loading = false;
  bool _placing = false;
  String? _error;

  List<Order> get orders => _orders;
  bool get loading => _loading;
  bool get placing => _placing;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _orders = await _service.list();
    } catch (e) {
      _error = _message(e, fallback: 'Pesanan tidak bisa dimuat. Tarik ke bawah untuk mencoba lagi.');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<PlaceResult> place(PlaceOrder request) async {
    _placing = true;
    notifyListeners();
    try {
      final order = await _service.place(request);
      _orders = [order, ..._orders];
      return (order: order, error: null);
    } catch (e) {
      return (
        order: null,
        error: _message(e, fallback: 'Pesanan tidak terkirim. Periksa koneksi internet lalu coba lagi.'),
      );
    } finally {
      _placing = false;
      notifyListeners();
    }
  }

  /// Ganti pesanan yang sudah ada di daftar dengan versi terbaru (mis. setelah dibatalkan).
  void replace(Order order) {
    _orders = [for (final o in _orders) o.id == order.id ? order : o];
    notifyListeners();
  }

  void reset() {
    _orders = [];
    _error = null;
    notifyListeners();
  }

  String _message(Object e, {required String fallback}) {
    if (e is! ApiException) return fallback;
    if (e.statusCode == 404) {
      return 'Pembuatan pesanan belum tersedia. Keranjang Anda tetap tersimpan.';
    }
    final field = e.errors?.values.firstOrNull;
    if (field is List && field.isNotEmpty) return '${field.first}';
    return e.statusCode >= 500 ? fallback : e.message;
  }
}
