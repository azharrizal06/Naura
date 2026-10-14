import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../services/api_client.dart';
import '../services/api_error.dart';
import '../services/auth_service.dart';

/// waking = server belum membalas, sedang dicoba lagi (hosting gratis tidur saat sepi).
/// unreachable = ada token tersimpan tetapi server tetap tidak bisa dihubungi.
enum AuthStatus { unknown, waking, authenticated, unauthenticated, unreachable }

/// Status login customer. Aksi mengembalikan pesan error (null = berhasil).
class AuthController extends ChangeNotifier {
  /// [wakeAttempts] × (timeout + [wakeDelay]) ≈ 1,5 menit — cukup untuk server yang baru bangun.
  AuthController(
    this._authService, {
    this.wakeAttempts = 6,
    this.wakeDelay = const Duration(seconds: 3),
  });

  final AuthService _authService;
  final int wakeAttempts;
  final Duration wakeDelay;

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
      // Bangunkan server selagi pengguna mengisi form masuk; hasilnya diabaikan.
      unawaited(_authService.warmUp());
      _setUnauthenticated();
      notifyListeners();
      return;
    }
    for (var attempt = 1; attempt <= wakeAttempts; attempt++) {
      try {
        _user = await _authService.me();
        _status = AuthStatus.authenticated;
        break;
      } on ApiException catch (e) {
        // 401/403: token tidak berlaku → login ulang (tanpa coba lagi).
        if (e.statusCode == 401 || e.statusCode == 403) {
          _setUnauthenticated();
          break;
        }
        _status = AuthStatus.unreachable; // 5xx (mis. 502 saat proxy menunggu server bangun)
      } catch (_) {
        _status = AuthStatus.unreachable; // timeout, koneksi ditolak, tidak ada jaringan
      }
      if (attempt < wakeAttempts) {
        _status = AuthStatus.waking;
        notifyListeners();
        await Future<void>.delayed(wakeDelay);
      }
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

  /// Email diganti? (spasi & huruf besar/kecil diabaikan) — bila ya, butuh password saat ini.
  bool emailChanged(String email) =>
      email.trim().toLowerCase() != (_user?.email ?? '').toLowerCase();

  /// Ubah profil; `null` = berhasil, selain itu pesan error.
  Future<String?> updateProfile({
    required String name,
    required String? phone,
    required String email,
    String? currentPassword,
  }) =>
      _account(() async {
        _user = await _authService.updateProfile(
          name: name.trim(),
          phone: (phone == null || phone.trim().isEmpty) ? null : phone.trim(),
          email: email.trim(),
          currentPassword: emailChanged(email) ? currentPassword : null,
        );
      }, fallback: 'Profil tidak bisa disimpan. Periksa koneksi lalu coba lagi.');

  /// Ganti password; perangkat lain akan keluar. `null` = berhasil.
  Future<String?> changePassword({required String currentPassword, required String newPassword}) =>
      _account(
        () => _authService.changePassword(currentPassword: currentPassword, newPassword: newPassword),
        fallback: 'Password tidak bisa diganti. Periksa koneksi lalu coba lagi.',
      );

  Future<String?> _account(Future<void> Function() action, {required String fallback}) async {
    _busy = true;
    notifyListeners();
    try {
      await action();
      return null;
    } catch (e) {
      return apiErrorMessage(e, fallback: fallback);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

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
      return 'Server tidak bisa dihubungi. Bila baru dibuka, server mungkin sedang dinyalakan — tunggu sebentar lalu coba lagi.';
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
