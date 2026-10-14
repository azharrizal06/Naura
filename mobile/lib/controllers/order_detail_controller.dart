import 'package:flutter/foundation.dart';

import '../models/order.dart';
import '../services/order_service.dart';

/// Detail satu pesanan. [initial] menampilkan data yang sudah ada
/// (mis. baru dibuat) sambil memuat versi terbaru.
class OrderDetailController extends ChangeNotifier {
  OrderDetailController(this._service, {Order? initial})
      : _order = initial,
        _loading = initial == null;

  final OrderService _service;

  Order? _order;
  bool _loading;
  String? _error;

  Order? get order => _order;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load(int id) async {
    _error = null;
    try {
      _order = await _service.find(id);
    } catch (_) {
      if (_order == null) {
        _error = 'Pesanan ini tidak bisa dimuat. Kembali lalu coba buka lagi.';
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
