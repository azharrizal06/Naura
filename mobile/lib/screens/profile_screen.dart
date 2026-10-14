import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../widgets/error_box.dart';

/// Ubah nama, HP, dan email. Ganti email butuh password saat ini.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  final _passwordCtrl = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthController>().user;
    _nameCtrl = TextEditingController(text: user?.name ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
    _emailCtrl = TextEditingController(text: user?.email ?? '')..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);
    final error = await context.read<AuthController>().updateProfile(
          name: _nameCtrl.text,
          phone: _phoneCtrl.text,
          email: _emailCtrl.text,
          currentPassword: _passwordCtrl.text,
        );
    if (!mounted) return;
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil tersimpan.')));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final emailChanged = auth.emailChanged(_emailCtrl.text);

    return Scaffold(
      appBar: AppBar(title: const Text('Ubah profil')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            if (_error != null) ...[ErrorBox(_error!), const SizedBox(height: 16)],
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nama'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Isi nama Anda' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Nomor HP (opsional)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email', helperText: 'Dipakai untuk masuk dan menerima kode reset'),
              validator: (v) => (v == null || !v.contains('@')) ? 'Isi email yang valid' : null,
            ),
            if (emailChanged) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordCtrl,
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                decoration: const InputDecoration(labelText: 'Password saat ini', helperText: 'Wajib untuk mengganti email'),
                validator: (v) => (v == null || v.isEmpty) ? 'Masukkan password saat ini' : null,
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: auth.busy ? null : _save,
              child: Text(auth.busy ? 'Menyimpan…' : 'Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}
