import 'package:flutter_test/flutter_test.dart';

import 'package:naura_mobile/controllers/password_reset_controller.dart';
import 'package:naura_mobile/services/api_client.dart';

import '../fakes/fake_services.dart';

void main() {
  late FakeAuthService service;
  late PasswordResetController c;

  setUp(() {
    service = FakeAuthService();
    c = PasswordResetController(service);
  });

  test('mulai di langkah email', () {
    expect(c.step, ResetStep.email);
  });

  test('requestCode mengirim email (dirapikan) lalu pindah ke langkah kode', () async {
    final error = await c.requestCode('  Budi@Naura.test ');
    expect(error, isNull);
    expect(service.codeRequests, ['budi@naura.test']);
    expect(c.step, ResetStep.code);
    expect(c.email, 'budi@naura.test');
    expect(c.busy, isFalse);
  });

  test('requestCode gagal → tetap di langkah email', () async {
    service.accountError = ApiException(429, 'Terlalu banyak percobaan. Coba lagi dalam 60 detik.');
    final error = await c.requestCode('budi@naura.test');
    expect(error, 'Terlalu banyak percobaan. Coba lagi dalam 60 detik.');
    expect(c.step, ResetStep.email);
  });

  test('reset berhasil → langkah selesai dengan email yang sama', () async {
    await c.requestCode('budi@naura.test');
    final error = await c.reset(code: ' 123456 ', password: 'sandibaru123');
    expect(error, isNull);
    expect(service.lastReset, (email: 'budi@naura.test', code: '123456', password: 'sandibaru123'));
    expect(c.step, ResetStep.done);
  });

  test('kode salah → pesan field, tetap di langkah kode', () async {
    await c.requestCode('budi@naura.test');
    service.accountError = ApiException(422, 'x', errors: {
      'code': ['Kode salah atau sudah kedaluwarsa.'],
    });
    final error = await c.reset(code: '000000', password: 'sandibaru123');
    expect(error, 'Kode salah atau sudah kedaluwarsa.');
    expect(c.step, ResetStep.code);
  });

  test('kirim ulang kode tetap di langkah kode', () async {
    await c.requestCode('budi@naura.test');
    expect(await c.resend(), isNull);
    expect(service.codeRequests, ['budi@naura.test', 'budi@naura.test']);
    expect(c.step, ResetStep.code);
  });

  test('backToEmail kembali ke langkah email', () async {
    await c.requestCode('budi@naura.test');
    c.backToEmail();
    expect(c.step, ResetStep.email);
  });
}
