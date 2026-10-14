import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

/// unreachable = ada token tersimpan tetapi server tidak bisa dihubungi.
enum AuthStatus { unknown, authenticated, unauthenticated, unreachable }

/// Status login customer. Aksi mengembalikan pesan error (null = berhasil).
class AuthController extends ChangeNotifier {
  AuthController(this._authService);

  final AuthService _authService;

  AuthStatus _status = AuthStatus.unknown;
  User? _user;
  bool _busy = false;

  AuthStatus get status => _status;
  User? get user => _user;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get busy => _busy;

  /// Dipanggil saat startup (dan "Coba lagi" di splash): cek token tersimpan.
  Future<void> bootstrap() async {
    if (_status != AuthStatus.unknown) {
      _status = AuthStatus.unknown;
      notifyListeners();
    }
    final token = await _authService.loadToken();
    if (token == null) {
      _setUnauthenticated();
      notifyListeners();
      return;
    }
    try {
      _user = await _authService.me();
      _status = AuthStatus.authenticated;
    } on ApiException catch (e) {
      // 401/403: token tidak berlaku → login ulang. Lainnya (5xx): server bermasalah.
      if (e.statusCode == 401 || e.statusCode == 403) {
        _setUnauthenticated();
      } else {
        _status = AuthStatus.unreachable;
      }
    } catch (_) {
      // Timeout, koneksi ditolak, tidak ada jaringan.
      _status = AuthStatus.unreachable;
    }
    notifyListeners();
  }

  Future<String?> login(String email, String password) =>
      _run(() => _authService.login(email, password));

  Future<String?> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) =>
      _run(() => _authService.register(
            name: name,
            email: email,
            password: password,
            phone: phone,
          ));

  Future<void> logout() async {
    await _authService.logout();
    _setUnauthenticated();
    notifyListeners();
  }

  Future<String?> _run(Future<AuthResult> Function() action) async {
    _busy = true;
    notifyListeners();
    try {
      final result = await action();
      _user = result.user;
      _status = AuthStatus.authenticated;
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Server tidak bisa dihubungi. Periksa koneksi internet lalu coba lagi.';
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void _setUnauthenticated() {
    _user = null;
    _status = AuthStatus.unauthenticated;
  }
}
