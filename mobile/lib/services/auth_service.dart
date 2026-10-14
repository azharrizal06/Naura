import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import 'api_client.dart';

/// Hasil autentikasi: user + token.
class AuthResult {
  final User user;
  final String token;
  AuthResult(this.user, this.token);
}

class AuthService {
  AuthService(this._api);

  final ApiClient _api;
  static const _tokenKey = 'naura_token';

  Future<String?> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    _api.setToken(token);
    return token;
  }

  Future<void> _persistToken(String? token) async {
    final prefs = await SharedPreferences.getInstance();
    if (token == null) {
      await prefs.remove(_tokenKey);
    } else {
      await prefs.setString(_tokenKey, token);
    }
    _api.setToken(token);
  }

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final data = await _api.post('/auth/register', body: {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': password,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      'device_name': 'flutter-app',
    }) as Map<String, dynamic>;

    final result = AuthResult(
      User.fromJson(data['user'] as Map<String, dynamic>),
      data['token'] as String,
    );
    await _persistToken(result.token);
    return result;
  }

  Future<AuthResult> login(String email, String password) async {
    final data = await _api.post('/auth/login', body: {
      'email': email,
      'password': password,
      'device_name': 'flutter-app',
    }) as Map<String, dynamic>;

    final result = AuthResult(
      User.fromJson(data['user'] as Map<String, dynamic>),
      data['token'] as String,
    );
    await _persistToken(result.token);
    return result;
  }

  /// Permintaan ringan untuk membangunkan server (hosting gratis tidur saat sepi).
  Future<void> warmUp() async {
    try {
      await _api.get('/store');
    } catch (_) {
      // Abaikan — hanya pemanasan.
    }
  }

  Future<User> me() async {
    final res = await _api.get('/auth/me') as Map<String, dynamic>;
    return User.fromJson(res['data'] as Map<String, dynamic>);
  }
 
  // --- Lupa password (kode 6 digit via email) ---

  /// Minta kode reset; server selalu menjawab sama (email terdaftar atau tidak).
  Future<String> forgotPassword(String email) async {
    final res = await _api.post('/auth/forgot-password', body: {'email': email}) as Map<String, dynamic>;
    return res['message'] as String;
  }

  Future<String> resetPassword({required String email, required String code, required String password}) async {
    final res = await _api.post('/auth/reset-password', body: {
      'email': email,
      'code': code,
      'password': password,
      'password_confirmation': password,
    }) as Map<String, dynamic>;
    return res['message'] as String;
  }

  // --- Profil & password ---

  /// [currentPassword] wajib bila email diganti.
  Future<User> updateProfile({required String name, String? phone, required String email, String? currentPassword}) async {
    final res = await _api.patch('/auth/profile', body: {
      'name': name,
      'phone': phone,
      'email': email,
      'current_password': ?currentPassword,
    }) as Map<String, dynamic>;
    return User.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<String> changePassword({required String currentPassword, required String newPassword}) async {
    final res = await _api.put('/auth/password', body: {
      'current_password': currentPassword,
      'password': newPassword,
      'password_confirmation': newPassword,
    }) as Map<String, dynamic>;
    return res['message'] as String;
  }

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } finally {
      await _persistToken(null);
    }
  }
}
