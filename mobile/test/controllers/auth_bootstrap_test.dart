import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:naura_mobile/controllers/auth_controller.dart';
import 'package:naura_mobile/services/api_client.dart';
import 'package:naura_mobile/services/auth_service.dart';

const _user = {
  'id': 3,
  'name': 'Budi Customer',
  'email': 'customer@naura.test',
  'phone': null,
  'role': 'customer',
  'role_label': 'Customer',
  'is_active': true,
};

AuthController _controller(http.Client client) => AuthController(
      AuthService(ApiClient(client: client, timeout: const Duration(milliseconds: 100))),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({'naura_token': 'tok'}));

  test('server tidak membalas → bootstrap tetap selesai (tidak tertahan di splash)', () async {
    final c = _controller(MockClient((_) => Completer<http.Response>().future));

    await c.bootstrap().timeout(const Duration(seconds: 2));

    expect(c.status, AuthStatus.unreachable);
  });

  test('server tidak bisa dihubungi → status unreachable, token tidak dihapus', () async {
    final c = _controller(MockClient((_) => throw http.ClientException('Connection refused')));

    await c.bootstrap();

    expect(c.status, AuthStatus.unreachable);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('naura_token'), 'tok');
  });

  test('token ditolak server (401) → harus login lagi', () async {
    final c = _controller(MockClient((_) async => http.Response('{"message":"Unauthenticated."}', 401)));

    await c.bootstrap();

    expect(c.status, AuthStatus.unauthenticated);
  });

  test('coba lagi setelah server kembali → masuk tanpa login ulang', () async {
    var up = false;
    final c = _controller(MockClient((_) async {
      if (!up) throw http.ClientException('Connection refused');
      return http.Response(jsonEncode({'data': _user}), 200);
    }));

    await c.bootstrap();
    expect(c.status, AuthStatus.unreachable);

    up = true;
    await c.bootstrap();
    expect(c.status, AuthStatus.authenticated);
    expect(c.user?.email, 'customer@naura.test');
  });
}
