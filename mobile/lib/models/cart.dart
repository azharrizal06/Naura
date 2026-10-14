/// Satu baris keranjang dari `GET /api/cart`.
class CartItem {
  final int id;
  final int variantId;
  final String variantName;
  final int productId;
  final String productName;
  final String productSlug;
  final String? imageUrl;
  final int unitPrice;
  final int quantity;
  final int stock;

  const CartItem({
    required this.id,
    required this.variantId,
    required this.variantName,
    required this.productId,
    required this.productName,
    required this.productSlug,
    required this.imageUrl,
    required this.unitPrice,
    required this.quantity,
    required this.stock,
  });

  int get lineTotal => unitPrice * quantity;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>;
    return CartItem(
      id: json['id'] as int,
      variantId: json['variant_id'] as int,
      variantName: json['variant_name'] as String,
      productId: product['id'] as int,
      productName: product['name'] as String,
      productSlug: product['slug'] as String,
      imageUrl: product['primary_image'] as String?,
      unitPrice: json['unit_price'] as int,
      quantity: json['quantity'] as int,
      stock: json['stock'] as int,
    );
  }

  CartItem copyWith({int? quantity}) => CartItem(
        id: id,
        variantId: variantId,
        variantName: variantName,
        productId: productId,
        productName: productName,
        productSlug: productSlug,
        imageUrl: imageUrl,
        unitPrice: unitPrice,
        quantity: quantity ?? this.quantity,
        stock: stock,
      );
}

/// Keranjang beserta total yang dihitung server.
class Cart {
  final List<CartItem> items;
  final int count;
  final int subtotal;
  final int shippingCost;
  final int total;

  const Cart({
    required this.items,
    required this.count,
    required this.subtotal,
    required this.shippingCost,
    required this.total,
  });

  static const empty = Cart(items: [], count: 0, subtotal: 0, shippingCost: 0, total: 0);

  bool get isEmpty => items.isEmpty;

  factory Cart.fromJson(Map<String, dynamic> json) => Cart(
        items: (json['items'] as List<dynamic>)
            .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        count: json['count'] as int,
        subtotal: json['subtotal'] as int,
        shippingCost: json['shipping_cost'] as int,
        total: json['total'] as int,
      );
}
