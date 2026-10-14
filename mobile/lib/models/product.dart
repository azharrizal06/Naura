class ProductListItem {
  final int id;
  final String name;
  final String slug;
  final int basePrice;
  final String? categoryName;
  final String? primaryImage;

  const ProductListItem({
    required this.id,
    required this.name,
    required this.slug,
    required this.basePrice,
    required this.categoryName,
    required this.primaryImage,
  });

  factory ProductListItem.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as Map<String, dynamic>?;
    return ProductListItem(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      basePrice: (json['base_price'] ?? 0) as int,
      categoryName: category?['name'] as String?,
      primaryImage: json['primary_image'] as String?,
    );
  }
}

class ProductVariant {
  final int id;
  final String sku;
  final String name;
  final int price;
  final int stock;
  final bool inStock;

  const ProductVariant({
    required this.id,
    required this.sku,
    required this.name,
    required this.price,
    required this.stock,
    required this.inStock,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'] as int,
      sku: json['sku'] as String,
      name: json['name'] as String,
      price: (json['price'] ?? 0) as int,
      stock: (json['stock'] ?? 0) as int,
      inStock: (json['in_stock'] ?? false) as bool,
    );
  }
}

class ProductDetail {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final int basePrice;
  final String? categoryName;
  final List<String> images;
  final List<ProductVariant> variants;

  const ProductDetail({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.basePrice,
    required this.categoryName,
    required this.images,
    required this.variants,
  });

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as Map<String, dynamic>?;
    final images = (json['images'] as List<dynamic>? ?? [])
        .map((e) => (e as Map<String, dynamic>)['url'] as String?)
        .whereType<String>()
        .toList();
    final variants = (json['variants'] as List<dynamic>? ?? [])
        .map((e) => ProductVariant.fromJson(e as Map<String, dynamic>))
        .toList();

    return ProductDetail(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
      basePrice: (json['base_price'] ?? 0) as int,
      categoryName: category?['name'] as String?,
      images: images,
      variants: variants,
    );
  }
}
