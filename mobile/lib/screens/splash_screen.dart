import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../theme/naura_theme.dart';
import 'main_shell.dart';
import 'login_screen.dart';

/// Menentukan layar awal berdasarkan status autentikasi.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthController>().status;

    switch (status) {
      case AuthStatus.unknown:
        return Scaffold(
          backgroundColor: NauraColors.terong,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('naura', style: display(56, color: Colors.white)),
                const SizedBox(height: 24),
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: NauraColors.kuningan),
                ),
              ],
            ),
          ),
        );
      case AuthStatus.waking:
        return Scaffold(
          backgroundColor: NauraColors.terong,
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('naura', style: display(56, color: Colors.white)),
                    const SizedBox(height: 24),
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: NauraColors.kuningan),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Server sedang dinyalakan…',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Biasanya kurang dari satu menit bila toko lama tidak dikunjungi. Aplikasi mencoba lagi otomatis.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFFC9BCCF), height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      case AuthStatus.unreachable:
        return Scaffold(
          backgroundColor: NauraColors.terong,
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('naura', style: display(56, color: Colors.white)),
                    const SizedBox(height: 24),
                    const Text(
                      'Server tidak bisa dihubungi',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Periksa koneksi internet, lalu coba lagi. Anda tidak perlu masuk ulang.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFFC9BCCF), height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: 200,
                      child: FilledButton(
                        onPressed: context.read<AuthController>().bootstrap,
                        child: const Text('Coba lagi'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      case AuthStatus.authenticated:
        return const MainShell();
      case AuthStatus.unauthenticated:
        return const LoginScreen();
    }
  }
}
