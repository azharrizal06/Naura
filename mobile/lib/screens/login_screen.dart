import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../controllers/auth_controller.dart';
import '../theme/naura_theme.dart';
import '../widgets/error_box.dart';
import '../widgets/fabric_bolts.dart';
import 'forgot_password_screen.dart';
import 'main_shell.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  // Terisi otomatis hanya saat debug atau build demo — bukan di rilis biasa.
  static const _prefill = kDebugMode || AppConfig.demoMode;
  final _emailCtrl = TextEditingController(text: _prefill ? AppConfig.demoEmail : '');
  final _passwordCtrl = TextEditingController(text: _prefill ? AppConfig.demoPassword : '');
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);
    final error = await context
        .read<AuthController>()
        .login(_emailCtrl.text.trim(), _passwordCtrl.text);
    if (!mounted) return;
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<AuthController>().busy;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: NauraColors.terong,
              padding: EdgeInsets.fromLTRB(
                  24, MediaQuery.of(context).padding.top + 40, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppConfig.appName,
                      style: display(76, color: Colors.white).copyWith(height: 0.95)),
                  const SizedBox(height: 12),
                  const Text(
                    'Gamis, hijab, dan mukena untuk dipakai setiap hari.',
                    style: TextStyle(color: Color(0xFFC9BCCF), fontSize: 15, height: 1.45),
                  ),
                  const SizedBox(height: 32),
                  const FabricBolts(height: 96),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Masuk', style: display(28)),
                    const SizedBox(height: 20),
                    if (AppConfig.demoMode) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: NauraColors.plumTint,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Versi demo — akun sudah terisi: ${AppConfig.demoEmail} / ${AppConfig.demoPassword}. '
                          'Data toko contoh, bukan pesanan sungguhan.',
                          style: TextStyle(fontSize: 13, height: 1.5, color: NauraColors.terong),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_error != null) ...[
                      ErrorBox(_error!),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Isi email yang terdaftar' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      decoration: const InputDecoration(labelText: 'Password'),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Isi password Anda' : null,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: busy
                            ? null
                            : () => Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => ForgotPasswordScreen(initialEmail: _emailCtrl.text.trim()),
                                )),
                        child: const Text('Lupa password?'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: busy ? null : _submit,
                      child: busy
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Masuk'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: busy
                          ? null
                          : () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const RegisterScreen()),
                              ),
                      child: const Text('Belum punya akun? Daftar'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
