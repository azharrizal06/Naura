import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/password_reset_controller.dart';
import '../services/auth_service.dart';
import '../theme/naura_theme.dart';
import '../widgets/error_box.dart';

/// Lupa password: email → kode 6 digit + password baru → kembali ke login.
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PasswordResetController(context.read<AuthService>()),
      child: _ForgotPasswordView(initialEmail: initialEmail),
    );
  }
}

class _ForgotPasswordView extends StatefulWidget {
  const _ForgotPasswordView({required this.initialEmail});
  final String initialEmail;

  @override
  State<_ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<_ForgotPasswordView> {
  final _emailForm = GlobalKey<FormState>();
  final _codeForm = GlobalKey<FormState>();
  late final _emailCtrl = TextEditingController(text: widget.initialEmail);
  final _codeCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String? _error;
  String? _info;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    if (!_emailForm.currentState!.validate()) return;
    setState(() => _error = null);
    final error = await context.read<PasswordResetController>().requestCode(_emailCtrl.text);
    if (mounted) setState(() => _error = error);
  }

  Future<void> _resend() async {
    setState(() {
      _error = null;
      _info = null;
    });
    final error = await context.read<PasswordResetController>().resend();
    if (!mounted) return;
    setState(() {
      _error = error;
      _info = error == null ? 'Kode baru sudah dikirim. Kode sebelumnya tidak berlaku lagi.' : null;
    });
  }

  Future<void> _reset() async {
    if (!_codeForm.currentState!.validate()) return;
    setState(() {
      _error = null;
      _info = null;
    });
    final error = await context
        .read<PasswordResetController>()
        .reset(code: _codeCtrl.text, password: _passwordCtrl.text);
    if (mounted) setState(() => _error = error);
  }

  @override
  Widget build(BuildContext context) {
    final reset = context.watch<PasswordResetController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Lupa password')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          if (_error != null) ...[ErrorBox(_error!), const SizedBox(height: 16)],
          switch (reset.step) {
            ResetStep.email => _emailStep(reset.busy),
            ResetStep.code => _codeStep(reset),
            ResetStep.done => _doneStep(),
          },
        ],
      ),
    );
  }

  Widget _emailStep(bool busy) {
    return Form(
      key: _emailForm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Atur ulang password', style: display(26)),
          const SizedBox(height: 8),
          const Text(
            'Masukkan email akun Anda. Kami kirim kode 6 digit untuk membuat password baru.',
            style: TextStyle(color: NauraColors.muted, height: 1.5),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(labelText: 'Email'),
            validator: (v) => (v == null || !v.contains('@')) ? 'Isi email yang terdaftar' : null,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: busy ? null : _requestCode,
            child: Text(busy ? 'Mengirim…' : 'Kirim kode'),
          ),
        ],
      ),
    );
  }

  Widget _codeStep(PasswordResetController reset) {
    return Form(
      key: _codeForm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Masukkan kode', style: display(26)),
          const SizedBox(height: 8),
          Text(
            'Bila ${reset.email} terdaftar, kode sudah dikirim ke email tersebut. Kode berlaku 15 menit.',
            style: const TextStyle(color: NauraColors.muted, height: 1.5),
          ),
          if (_info != null) ...[
            const SizedBox(height: 8),
            Text(_info!, style: const TextStyle(color: NauraColors.plum, fontSize: 13)),
          ],
          const SizedBox(height: 20),
          TextFormField(
            controller: _codeCtrl,
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
            maxLength: 6,
            decoration: const InputDecoration(labelText: 'Kode 6 digit', counterText: ''),
            validator: (v) => (v == null || !RegExp(r'^\d{6}$').hasMatch(v.trim())) ? 'Kode terdiri dari 6 angka' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _passwordCtrl,
            obscureText: true,
            autofillHints: const [AutofillHints.newPassword],
            decoration: const InputDecoration(labelText: 'Password baru', helperText: 'Minimal 8 karakter'),
            validator: (v) => (v == null || v.length < 8) ? 'Password minimal 8 karakter' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _confirmCtrl,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Ulangi password baru'),
            validator: (v) => v != _passwordCtrl.text ? 'Password tidak sama' : null,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: reset.busy ? null : _reset,
            child: Text(reset.busy ? 'Menyimpan…' : 'Simpan password baru'),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(onPressed: reset.busy ? null : reset.backToEmail, child: const Text('Ganti email')),
              TextButton(onPressed: reset.busy ? null : _resend, child: const Text('Kirim ulang kode')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _doneStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Password diganti', style: display(26)),
        const SizedBox(height: 8),
        const Text(
          'Silakan masuk dengan password baru. Perangkat lain yang masih masuk dengan password lama sudah dikeluarkan.',
          style: TextStyle(color: NauraColors.muted, height: 1.5),
        ),
        const SizedBox(height: 24),
        FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Kembali ke halaman masuk')),
      ],
    );
  }
}
