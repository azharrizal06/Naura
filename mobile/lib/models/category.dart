class Category {
  final int id;
  final String name;
  final String slug;
  final int productsCount;

  const Category({
    required this.id,
    required this.name,
    required this.slug,
    required this.productsCount,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      productsCount: (json['products_count'] ?? 0) as int,
    );
  }
}
