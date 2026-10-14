import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/cart_controller.dart';
import '../controllers/nav_controller.dart';
import '../controllers/product_detail_controller.dart';
import '../models/product.dart';
import '../services/catalog_service.dart';
import '../theme/naura_theme.dart';
import '../utils/format.dart';
import '../utils/swatch.dart';
import '../widgets/fabric_image.dart';
import '../widgets/message_state.dart';
import '../widgets/variant_picker.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ProductDetailController(context.read<CatalogService>())..load(slug),
      child: const _ProductDetailView(),
    );
  }
}

class _ProductDetailView extends StatelessWidget {
  const _ProductDetailView();

  @override
  Widget build(BuildContext context) {
    final detail = context.watch<ProductDetailController>();
    final product = detail.product;

    return Scaffold(
      appBar: AppBar(),
      body: detail.loading
          ? const Center(child: CircularProgressIndicator())
          : product == null
              ? MessageState(message: detail.error ?? 'Produk tidak ditemukan.')
              : _ProductBody(product: product, selected: detail.selected),
      bottomNavigationBar:
          product == null ? null : _AddToCartBar(product: product, variant: detail.selected),
    );
  }
}

class _ProductBody extends StatelessWidget {
  const _ProductBody({required this.product, required this.selected});

  final ProductDetail product;
  final ProductVariant? selected;

  @override
  Widget build(BuildContext context) {
    final fabric =
        (selected != null ? swatchFor(selected!.name) : null) ?? softFabricFor(product.id);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: [
        FabricImage(url: product.images.firstOrNull, fallback: fabric),
        const SizedBox(height: 20),
        if (product.categoryName != null)
          Text(product.categoryName!,
              style: const TextStyle(fontSize: 13, color: NauraColors.muted)),
        const SizedBox(height: 4),
        Text(product.name, style: display(28)),
        const SizedBox(height: 10),
        Text(
          formatRupiah(selected?.price ?? product.basePrice),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 24),
        if (product.variants.isNotEmpty)
          VariantPicker(
            variants: product.variants,
            selected: selected,
            onSelect: context.read<ProductDetailController>().select,
          ),
        if (product.description != null) ...[
          const SizedBox(height: 28),
          const Divider(height: 1, color: NauraColors.garis),
          const SizedBox(height: 20),
          Text(product.description!, style: const TextStyle(fontSize: 15, height: 1.6)),
        ],
      ],
    );
  }
}

class _AddToCartBar extends StatelessWidget {
  const _AddToCartBar({required this.product, required this.variant});

  final ProductDetail product;
  final ProductVariant? variant;

  Future<void> _add(BuildContext context, ProductVariant variant) async {
    final error = await context.read<CartController>().add(variant.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(error ?? '${variant.name} masuk keranjang'),
        action: SnackBarAction(
          label: 'Lihat keranjang',
          textColor: const Color(0xFFD9C08A),
          onPressed: () {
            context.read<NavController>().go(NavTab.cart);
            Navigator.of(context).popUntil((r) => r.isFirst);
          },
        ),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<CartController>().busy;
    final v = variant;
    final inStock = v?.inStock ?? false;
    final String label;
    if (v == null) {
      label = 'Belum bisa dibeli';
    } else if (!inStock) {
      label = 'Stok habis';
    } else {
      label = 'Tambah ke keranjang';
    }

    return Container(
      decoration: const BoxDecoration(
        color: NauraColors.kabut,
        border: Border(top: BorderSide(color: NauraColors.garis)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: FilledButton(
            onPressed: inStock && !busy ? () => _add(context, v!) : null,
            child: Text(label),
          ),
        ),
      ),
    );
  }
}
