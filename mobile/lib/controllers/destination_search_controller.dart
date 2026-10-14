import 'package:flutter/foundation.dart';

import '../models/destination.dart';
import '../services/api_client.dart';
import '../services/shipping_service.dart';

/// Pencarian kecamatan/kelurahan untuk form alamat.
/// [unavailable] = server belum memakai RajaOngkir → alamat diisi manual.
class DestinationSearchController extends ChangeNotifier {
  DestinationSearchController(this._service);

  final ShippingService _service;

  List<Destination> _results = [];
  bool _loading = false;
  bool _unavailable = false;
  String? _error;
  int _request = 0;

  List<Destination> get results => _results;
  bool get loading => _loading;
  bool get unavailable => _unavailable;
  String? get error => _error;

  Future<void> search(String text) async {
    final query = text.trim();
    final request = ++_request;
    if (query.length < 3) {
      _results = [];
      _error = null;
      notifyListeners();
      return;
    }

    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await _service.searchDestinations(query);
      if (request != _request) return; // hasil ketikan lama
      _results = results;
    } on ApiException catch (e) {
      if (request != _request) return;
      _results = [];
      if (e.statusCode == 503) {
        _unavailable = true;
      } else {
        _error = 'Pencarian gagal. Coba lagi beberapa saat lagi.';
      }
    } catch (_) {
      if (request != _request) return;
      _error = 'Pencarian gagal. Periksa koneksi internet.';
    } finally {
      if (request == _request) {
        _loading = false;
        notifyListeners();
      }
    }
  }
}
