import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/catalog_controller.dart';
import '../theme/naura_theme.dart';
import '../widgets/category_tab.dart';
import '../widgets/message_state.dart';
import '../widgets/product_card.dart';
import 'product_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      context.read<CatalogController>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogController>();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Text('naura', style: display(34)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: TextField(
                controller: _searchCtrl,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Cari gamis, hijab, mukena',
                  prefixIcon: const Icon(Icons.search, color: NauraColors.muted),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: catalog.search,
              ),
            ),
            if (catalog.categories.isNotEmpty)
              SizedBox(
                height: 52,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    CategoryTab(
                      label: 'Semua',
                      selected: catalog.activeCategory == null,
                      onTap: () => catalog.selectCategory(null),
                    ),
                    for (final c in catalog.categories)
                      CategoryTab(
                        label: c.name,
                        selected: catalog.activeCategory == c.slug,
                        onTap: () => catalog.selectCategory(c.slug),
                      ),
                  ],
                ),
              ),
            const Divider(height: 1, color: NauraColors.garis),
            Expanded(child: _buildBody(catalog)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(CatalogController catalog) {
    final products = catalog.products;
    if (catalog.error != null && products.isEmpty) {
      return MessageState(
        message: catalog.error!,
        actionLabel: 'Muat ulang',
        onAction: catalog.refresh,
      );
    }
    if (products.isEmpty && catalog.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (products.isEmpty) {
      return MessageState(
        message: catalog.isFiltered
            ? 'Belum ada yang cocok. Coba kata lain atau pilih kategori Semua.'
            : 'Koleksi baru sedang disiapkan. Tarik ke bawah untuk memuat ulang.',
      );
    }

    return RefreshIndicator(
      onRefresh: catalog.refresh,
      child: GridView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.54,
          crossAxisSpacing: 14,
          mainAxisSpacing: 20,
        ),
        itemCount: products.length + (catalog.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= products.length) {
            return const Center(child: CircularProgressIndicator());
          }
          final product = products[index];
          return ProductCard(
            product: product,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ProductDetailScreen(slug: product.slug)),
            ),
          );
        },
      ),
    );
  }
}
