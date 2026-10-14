import 'package:flutter_test/flutter_test.dart';

import 'package:naura_mobile/controllers/auth_controller.dart';
import 'package:naura_mobile/services/api_client.dart';

import '../fakes/fake_services.dart';

void main() {
  test('bootstrap tanpa token → belum login', () async {
    final c = AuthController(FakeAuthService());
    await c.bootstrap();
    expect(c.status, AuthStatus.unauthenticated);
  });

  test('bootstrap dengan token → login sebagai user dari /auth/me', () async {
    final c = AuthController(FakeAuthService()..token = 'tok');
    await c.bootstrap();
    expect(c.status, AuthStatus.authenticated);
    expect(c.user?.email, 'customer@naura.test');
  });

  test('login gagal mengembalikan pesan API dan tetap belum login', () async {
    final c = AuthController(
        FakeAuthService()..loginError = ApiException(422, 'Email atau password salah.'));
    final error = await c.login('a@b.c', 'x');
    expect(error, 'Email atau password salah.');
    expect(c.isAuthenticated, isFalse);
    expect(c.busy, isFalse);
  });

  test('login berhasil mengembalikan null', () async {
    final c = AuthController(FakeAuthService());
    expect(await c.login('customer@naura.test', 'password'), isNull);
    expect(c.isAuthenticated, isTrue);
  });
}
