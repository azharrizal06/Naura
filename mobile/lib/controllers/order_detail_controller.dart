import 'package:flutter/foundation.dart';

import '../models/order.dart';
import '../services/api_error.dart';
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
  bool _busy = false;

  Order? get order => _order;
  bool get loading => _loading;
  String? get error => _error;

  /// Sedang membatalkan / menandai diterima.
  bool get busy => _busy;

  /// Customer hanya bisa membatalkan pesanan yang belum dibayar.
  bool get canCancel => _order?.status == OrderStatus.pending;

  /// Paket yang sedang dikirim bisa ditandai sudah diterima.
  bool get canComplete => _order?.status == OrderStatus.shipped;

  /// Batalkan pesanan; `null` = berhasil, selain itu pesan error.
  Future<String?> cancel() =>
      _act(_service.cancel, fallback: 'Pesanan tidak bisa dibatalkan saat ini. Coba lagi.');

  /// Tandai pesanan diterima; `null` = berhasil, selain itu pesan error.
  Future<String?> complete() =>
      _act(_service.complete, fallback: 'Pesanan tidak bisa ditandai diterima saat ini. Coba lagi.');

  Future<String?> _act(Future<Order> Function(int id) action, {required String fallback}) async {
    final current = _order;
    if (current == null) return 'Pesanan tidak ditemukan.';
    _busy = true;
    notifyListeners();
    try {
      _order = await action(current.id);
      return null;
    } catch (e) {
      return apiErrorMessage(e, fallback: fallback);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

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
