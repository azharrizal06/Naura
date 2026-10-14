import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/address_controller.dart';
import '../models/address.dart';
import '../theme/naura_theme.dart';
import '../widgets/address_card.dart';
import '../widgets/message_state.dart';
import 'address_form_screen.dart';

/// Daftar alamat tersimpan. Dengan [pick] = true, mengetuk alamat
/// mengembalikannya ke layar sebelumnya (dipakai dari checkout).
class AddressesScreen extends StatelessWidget {
  const AddressesScreen({super.key, this.pick = false, this.selectedId});

  final bool pick;
  final int? selectedId;

  Future<void> _openForm(BuildContext context, [Address? address]) async {
    final saved = await Navigator.of(context).push<Address>(
      MaterialPageRoute(builder: (_) => AddressFormScreen(address: address)),
    );
    if (saved != null && pick && context.mounted) Navigator.of(context).pop(saved);
  }

  Future<void> _delete(BuildContext context, Address address) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Hapus alamat ${address.label}?'),
        content: const Text('Alamat ini tidak muncul lagi saat checkout. Pesanan lama tidak berubah.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: NauraColors.marun),
            child: const Text('Hapus alamat'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final error = await context.read<AddressController>().remove(address.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error ?? 'Alamat ${address.label} dihapus')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AddressController>();
    final addresses = controller.addresses;

    final Widget body;
    if (controller.loading && addresses.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (controller.error != null && addresses.isEmpty) {
      body = MessageState(message: controller.error!, actionLabel: 'Muat ulang', onAction: controller.load);
    } else if (addresses.isEmpty) {
      body = MessageState(
        title: 'Belum ada alamat',
        message: 'Simpan alamat sekali, lalu pilih saja saat checkout berikutnya.',
        actionLabel: 'Tambah alamat',
        onAction: () => _openForm(context),
      );
    } else {
      body = ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 4, 8, 24),
        itemCount: addresses.length,
        separatorBuilder: (_, _) => const Divider(height: 1, color: NauraColors.garis),
        itemBuilder: (_, i) {
          final a = addresses[i];
          return AddressCard(
            address: a,
            onTap: pick ? () => Navigator.of(context).pop(a) : () => _openForm(context, a),
            trailing: pick
                ? Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Icon(
                      a.id == selectedId ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      color: a.id == selectedId ? NauraColors.plum : NauraColors.garisKuat,
                    ),
                  )
                : PopupMenuButton<String>(
                    tooltip: 'Pilihan untuk ${a.label}',
                    onSelected: (v) => v == 'edit' ? _openForm(context, a) : _delete(context, a),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Ubah')),
                      PopupMenuItem(value: 'delete', child: Text('Hapus')),
                    ],
                  ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(pick ? 'Pilih alamat' : 'Alamat pengiriman')),
      body: body,
      bottomNavigationBar: addresses.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: OutlinedButton.icon(
                  onPressed: () => _openForm(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah alamat'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: NauraColors.plum,
                    side: const BorderSide(color: NauraColors.garisKuat),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              ),
            ),
    );
  }
}
