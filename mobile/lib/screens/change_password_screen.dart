import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../theme/naura_theme.dart';
import '../widgets/error_box.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);
    final error = await context
        .read<AuthController>()
        .changePassword(currentPassword: _currentCtrl.text, newPassword: _newCtrl.text);
    if (!mounted) return;
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password diganti. Perangkat lain perlu masuk ulang.')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<AuthController>().busy;

    return Scaffold(
      appBar: AppBar(title: const Text('Ganti password')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            if (_error != null) ...[ErrorBox(_error!), const SizedBox(height: 16)],
            TextFormField(
              controller: _currentCtrl,
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              decoration: const InputDecoration(labelText: 'Password saat ini'),
              validator: (v) => (v == null || v.isEmpty) ? 'Masukkan password saat ini' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _newCtrl,
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
              validator: (v) => v != _newCtrl.text ? 'Password tidak sama' : null,
            ),
            const SizedBox(height: 12),
            const Text(
              'Setelah diganti, perangkat lain yang masih masuk akan dikeluarkan.',
              style: TextStyle(fontSize: 13, color: NauraColors.muted, height: 1.5),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: busy ? null : _save, child: Text(busy ? 'Menyimpan…' : 'Ganti password')),
          ],
        ),
      ),
    );
  }
}
