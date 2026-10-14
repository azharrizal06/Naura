import 'dart:io' show Platform;

/// Konfigurasi aplikasi.
class AppConfig {
  AppConfig._();

  /// Base URL REST API.
  ///
  /// - Android emulator mengakses host lewat 10.0.2.2
  /// - iOS simulator / desktop memakai 127.0.0.1
  ///
  /// Dapat dioverride saat build:
  ///   flutter run --dart-define=API_BASE_URL=https://api.naura.test/api
  static String get apiBaseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;

    const port = 8000;
    if (Platform.isAndroid) {
      return 'http://192.168.1.5:$port/api';
    }
    return 'http://192.168.1.5:$port/api';
  }

  static const String appName = 'naura';
}
