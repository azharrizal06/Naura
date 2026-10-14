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

  group('profil & password', () {
    late FakeAuthService service;
    late AuthController c;

    setUp(() async {
      service = FakeAuthService()..token = 'tok';
      c = AuthController(service);
      await c.bootstrap();
    });

    test('updateProfile berhasil memperbarui user di controller', () async {
      final error = await c.updateProfile(name: 'Budi Santoso', phone: '0812', email: 'customer@naura.test');
      expect(error, isNull);
      expect(c.user?.name, 'Budi Santoso');
      expect(c.user?.phone, '0812');
      expect(c.busy, isFalse);
    });

    test('updateProfile tanpa ganti email tidak mengirim password', () async {
      await c.updateProfile(name: 'X', phone: null, email: 'customer@naura.test', currentPassword: 'abc');
      expect(service.lastProfile?['current_password'], isNull);
    });

    test('updateProfile ganti email mengirim password saat ini', () async {
      await c.updateProfile(name: 'X', phone: null, email: 'baru@naura.test', currentPassword: 'rahasia123');
      expect(service.lastProfile?['current_password'], 'rahasia123');
      expect(c.user?.email, 'baru@naura.test');
    });

    test('emailChanged membandingkan tanpa beda huruf besar/kecil', () {
      expect(c.emailChanged(' Customer@Naura.test '), isFalse);
      expect(c.emailChanged('lain@naura.test'), isTrue);
    });

    test('updateProfile ditolak → pesan field pertama, user tidak berubah', () async {
      service.accountError = ApiException(422, 'x', errors: {
        'current_password': ['Password saat ini salah.'],
      });
      final error = await c.updateProfile(name: 'X', phone: null, email: 'baru@naura.test', currentPassword: 'salah');
      expect(error, 'Password saat ini salah.');
      expect(c.user?.email, 'customer@naura.test');
    });

    test('changePassword berhasil → null', () async {
      expect(await c.changePassword(currentPassword: 'lama12345', newPassword: 'baru123456'), isNull);
      expect(service.lastPasswordChange?.next, 'baru123456');
    });

    test('changePassword ditolak → pesan dari server', () async {
      service.accountError = ApiException(422, 'x', errors: {
        'current_password': ['Password saat ini salah.'],
      });
      expect(await c.changePassword(currentPassword: 'salah', newPassword: 'baru123456'), 'Password saat ini salah.');
    });
  });

  test('bootstrap tanpa token membangunkan server di latar belakang', () async {
    final service = FakeAuthService();
    await AuthController(service).bootstrap();
    expect(service.warmUps, 1);
  });
}
