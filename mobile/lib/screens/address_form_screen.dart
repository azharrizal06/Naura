import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/address_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/destination_search_controller.dart';
import '../models/address.dart';
import '../models/destination.dart';
import '../services/shipping_service.dart';
import '../theme/naura_theme.dart';
import '../utils/format.dart';

/// Tambah/ubah alamat. Kecamatan dipilih dari pencarian RajaOngkir supaya
/// ongkir kurir bisa dihitung; bila server belum memakai RajaOngkir,
/// kota, provinsi, dan kode pos diisi manual.
class AddressFormScreen extends StatelessWidget {
  const AddressFormScreen({super.key, this.address});

  final Address? address;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => DestinationSearchController(context.read<ShippingService>()),
      child: _AddressForm(address: address),
    );
  }
}

class _AddressForm extends StatefulWidget {
  const _AddressForm({this.address});

  final Address? address;

  @override
  State<_AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<_AddressForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _label;
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _line;
  late final TextEditingController _subdistrict;
  late final TextEditingController _district;
  late final TextEditingController _city;
  late final TextEditingController _province;
  late final TextEditingController _postal;
  final _search = TextEditingController();
  Timer? _debounce;
  int? _destinationId;
  late bool _isDefault;

  bool get _editing => widget.address != null;

  @override
  void initState() {
    super.initState();
    final a = widget.address;
    final user = context.read<AuthController>().user;
    _label = TextEditingController(text: a?.label ?? 'Rumah');
    _name = TextEditingController(text: a?.recipientName ?? user?.name ?? '');
    _phone = TextEditingController(text: a?.phone ?? user?.phone ?? '');
    _line = TextEditingController(text: a?.addressLine ?? '');
    _subdistrict = TextEditingController(text: a?.subdistrict ?? '');
    _district = TextEditingController(text: a?.district ?? '');
    _city = TextEditingController(text: a?.city ?? '');
    _province = TextEditingController(text: a?.province ?? '');
    _postal = TextEditingController(text: a?.postalCode ?? '');
    _destinationId = a?.destinationId;
    _isDefault = a?.isDefault ?? false;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final c in [_label, _name, _phone, _line, _subdistrict, _district, _city, _province, _postal, _search]) {
      c.dispose();
    }
    super.dispose();
  }

  void _onSearchChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400),
        () => context.read<DestinationSearchController>().search(text));
  }

  void _pick(Destination d) {
    setState(() {
      _destinationId = d.id;
      _subdistrict.text = titleCase(d.subdistrict ?? '');
      _district.text = titleCase(d.district ?? '');
      _city.text = titleCase(d.city ?? '');
      _province.text = titleCase(d.province ?? '');
      _postal.text = d.postalCode ?? '';
      _search.clear();
    });
    context.read<DestinationSearchController>().search('');
  }

  void _clearArea() => setState(() => _destinationId = null);

  Future<void> _save() async {
    final manual = context.read<DestinationSearchController>().unavailable;
    if (!manual && _destinationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cari lalu pilih kecamatan atau kelurahan tujuan.')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    String? opt(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
    final draft = Address(
      id: widget.address?.id ?? 0,
      label: _label.text.trim(),
      recipientName: _name.text.trim(),
      phone: _phone.text.trim(),
      addressLine: _line.text.trim(),
      subdistrict: opt(_subdistrict),
      district: opt(_district),
      city: _city.text.trim(),
      province: _province.text.trim(),
      postalCode: _postal.text.trim(),
      destinationId: _destinationId,
      isDefault: _isDefault,
    );
    final result = await context.read<AddressController>().save(draft);
    if (!mounted) return;
    if (result.address == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.error!)));
      return;
    }
    Navigator.of(context).pop(result.address);
  }

  @override
  Widget build(BuildContext context) {
    final search = context.watch<DestinationSearchController>();
    final saving = context.watch<AddressController>().saving;

    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Ubah alamat' : 'Alamat baru')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _LabelPicker(controller: _label, onChanged: () => setState(() {})),
            const SizedBox(height: 16),
            _field(_name, 'Nama penerima', hints: const [AutofillHints.name]),
            _field(_phone, 'No. HP',
                keyboard: TextInputType.phone,
                hints: const [AutofillHints.telephoneNumber],
                validator: (v) => (v == null || v.trim().length < 9)
                    ? 'Isi nomor HP aktif agar kurir bisa menghubungi'
                    : null),
            const SizedBox(height: 8),
            Text('Kecamatan atau kelurahan', style: display(18)),
            const SizedBox(height: 10),
            if (search.unavailable)
              ..._manualArea()
            else if (_destinationId != null)
              _PickedArea(
                text: [_subdistrict.text, _district.text, _city.text, _province.text]
                        .where((s) => s.isNotEmpty)
                        .join(', ') +
                    (_postal.text.isEmpty ? '' : ' ${_postal.text}'),
                onChange: _clearArea,
              )
            else
              ..._searchArea(search),
            const SizedBox(height: 16),
            _field(_line, 'Alamat lengkap',
                hint: 'Nama jalan, nomor rumah, RT/RW, patokan',
                lines: 3,
                hints: const [AutofillHints.streetAddressLine1]),
            CheckboxListTile(
              value: _isDefault,
              onChanged: (v) => setState(() => _isDefault = v ?? false),
              title: const Text('Jadikan alamat utama'),
              subtitle: const Text('Dipilih otomatis saat checkout'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              activeColor: NauraColors.plum,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton(
            onPressed: saving ? null : _save,
            child: Text(saving ? 'Menyimpan…' : _editing ? 'Simpan perubahan' : 'Simpan alamat'),
          ),
        ),
      ),
    );
  }

  List<Widget> _searchArea(DestinationSearchController search) => [
        TextField(
          controller: _search,
          onChanged: _onSearchChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Mis. Braga atau Coblong',
            prefixIcon: const Icon(Icons.search, color: NauraColors.muted),
            suffixIcon: search.loading
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : null,
          ),
        ),
        if (search.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(search.error!, style: const TextStyle(fontSize: 13, color: NauraColors.marun)),
          ),
        if (!search.loading && search.error == null && _search.text.trim().length >= 3 && search.results.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('Tidak ditemukan. Coba nama kecamatan atau kelurahan lain.',
                style: TextStyle(fontSize: 13, color: NauraColors.muted)),
          ),
        for (final d in search.results)
          InkWell(
            onTap: () => _pick(d),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: NauraColors.garis)),
              ),
              child: Text(titleCase(d.label),
                  style: const TextStyle(fontSize: 14, height: 1.4)),
            ),
          ),
      ];

  List<Widget> _manualArea() => [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text('Pencarian wilayah belum tersedia. Isi wilayah secara manual.',
              style: TextStyle(fontSize: 13, color: NauraColors.muted)),
        ),
        _field(_subdistrict, 'Kelurahan (opsional)', validator: (_) => null),
        _field(_district, 'Kecamatan (opsional)', validator: (_) => null),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _field(_city, 'Kota/Kabupaten', hints: const [AutofillHints.addressCity])),
            const SizedBox(width: 12),
            SizedBox(
              width: 120,
              child: _field(_postal, 'Kode pos',
                  keyboard: TextInputType.number,
                  hints: const [AutofillHints.postalCode],
                  validator: (v) =>
                      RegExp(r'^\d{5}$').hasMatch(v?.trim() ?? '') ? null : '5 angka'),
            ),
          ],
        ),
        _field(_province, 'Provinsi', hints: const [AutofillHints.addressState]),
      ];

  Widget _field(
    TextEditingController ctrl,
    String label, {
    String? hint,
    int lines = 1,
    TextInputType? keyboard,
    Iterable<String>? hints,
    FormFieldValidator<String>? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        minLines: lines,
        maxLines: lines,
        keyboardType: lines > 1 ? TextInputType.multiline : keyboard,
        autofillHints: hints,
        decoration: InputDecoration(labelText: label, hintText: hint, alignLabelWithHint: lines > 1),
        validator: validator ??
            (v) => (v == null || v.trim().isEmpty) ? 'Isi ${label.toLowerCase()}' : null,
      ),
    );
  }
}

/// Wilayah terpilih dari pencarian, dengan tombol untuk mencari ulang.
class _PickedArea extends StatelessWidget {
  const _PickedArea({required this.text, required this.onChange});

  final String text;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: NauraColors.garisKuat),
      ),
      child: Row(
        children: [
          const Icon(Icons.place_outlined, size: 20, color: NauraColors.plum),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(height: 1.4))),
          TextButton(onPressed: onChange, child: const Text('Ganti')),
        ],
      ),
    );
  }
}

/// Label alamat: pilihan cepat Rumah/Kantor, atau ketik sendiri.
class _LabelPicker extends StatelessWidget {
  const _LabelPicker({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    const presets = ['Rumah', 'Kantor', 'Kos'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          children: [
            for (final p in presets)
              ChoiceChip(
                label: Text(p),
                selected: controller.text == p,
                onSelected: (_) {
                  controller.text = p;
                  onChanged();
                },
                selectedColor: NauraColors.plumTint,
                side: const BorderSide(color: NauraColors.garisKuat),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                showCheckmark: false,
              ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller,
          onChanged: (_) => onChanged(),
          decoration: const InputDecoration(labelText: 'Label alamat'),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Beri nama alamat ini' : null,
        ),
      ],
    );
  }
}
