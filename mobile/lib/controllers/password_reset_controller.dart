import 'package:flutter/foundation.dart';

import '../services/api_error.dart';
import '../services/auth_service.dart';

enum ResetStep { email, code, done }

/// Alur lupa password: isi email → isi kode 6 digit + password baru → selesai.
/// Aksi mengembalikan pesan error (`null` = berhasil).
class PasswordResetController extends ChangeNotifier {
  PasswordResetController(this._service);

  final AuthService _service;

  ResetStep _step = ResetStep.email;
  String _email = '';
  bool _busy = false;

  ResetStep get step => _step;
  String get email => _email;
  bool get busy => _busy;

  Future<String?> requestCode(String email) async {
    _email = email.trim().toLowerCase();
    final error = await _run(() => _service.forgotPassword(_email),
        fallback: 'Kode tidak bisa dikirim. Periksa koneksi lalu coba lagi.');
    if (error == null) _step = ResetStep.code;
    notifyListeners();
    return error;
  }

  /// Kirim ulang kode ke email yang sama (kode lama tidak berlaku lagi).
  Future<String?> resend() => _run(() => _service.forgotPassword(_email),
      fallback: 'Kode tidak bisa dikirim. Periksa koneksi lalu coba lagi.');

  Future<String?> reset({required String code, required String password}) async {
    final error = await _run(
      () => _service.resetPassword(email: _email, code: code.trim(), password: password),
      fallback: 'Password tidak bisa diganti. Periksa koneksi lalu coba lagi.',
    );
    if (error == null) _step = ResetStep.done;
    notifyListeners();
    return error;
  }

  void backToEmail() {
    _step = ResetStep.email;
    notifyListeners();
  }

  Future<String?> _run(Future<void> Function() action, {required String fallback}) async {
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
}
