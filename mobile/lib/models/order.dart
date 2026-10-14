/// Pesanan customer — mengikuti tabel `orders`, `order_items`, `payments`,
/// `shipments` (lihat docs/database-schema.md).
enum OrderStatus {
  pending('Menunggu pembayaran'),
  paid('Dibayar'),
  processing('Diproses'),
  shipped('Dikirim'),
  completed('Selesai'),
  cancelled('Dibatalkan');

  const OrderStatus(this.label);
  final String label;

  /// Urutan alur normal; `cancelled` di luar urutan.
  static const steps = [pending, paid, processing, shipped, completed];

  int get step => steps.indexOf(this);

  static OrderStatus parse(String? value) =>
      values.where((s) => s.name == value).firstOrNull ?? pending;
}

class OrderItem {
  final int id;
  final String productName;
  final String variantName;
  final int unitPrice;
  final int quantity;
  final int subtotal;
  final int? productId;
  final String? imageUrl;

  const OrderItem({
    required this.id,
    required this.productName,
    required this.variantName,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
    required this.productId,
    required this.imageUrl,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    return OrderItem(
      id: json['id'] as int,
      productName: json['product_name'] as String,
      variantName: json['variant_name'] as String,
      unitPrice: json['unit_price'] as int,
      quantity: json['quantity'] as int,
      subtotal: json['subtotal'] as int,
      productId: product?['id'] as int?,
      imageUrl: product?['primary_image'] as String?,
    );
  }
}

class ShippingAddress {
  final String? label;
  final String recipientName;
  final String phone;
  final String addressLine;
  final String? subdistrict;
  final String? district;
  final String city;
  final String province;
  final String postalCode;

  const ShippingAddress({
    this.label,
    this.subdistrict,
    this.district,
    required this.recipientName,
    required this.phone,
    required this.addressLine,
    required this.city,
    required this.province,
    required this.postalCode,
  });

  factory ShippingAddress.fromJson(Map<String, dynamic> json) => ShippingAddress(
        label: json['label'] as String?,
        subdistrict: json['subdistrict'] as String?,
        district: json['district'] as String?,
        recipientName: json['recipient_name'] as String,
        phone: json['phone'] as String,
        addressLine: json['address_line'] as String,
        city: json['city'] as String,
        province: json['province'] as String,
        postalCode: json['postal_code'] as String,
      );

  String get areaLine {
    final parts = [subdistrict, district, city, province]
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .join(', ');
    return '$parts $postalCode';
  }
}

typedef BankAccount = ({String bank, String number, String holder});

class Payment {
  final String method;
  final String status;
  final int amount;
  final BankAccount? bank;
  final DateTime? paidAt;

  const Payment({
    required this.method,
    required this.status,
    required this.amount,
    required this.bank,
    required this.paidAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    final bank = json['bank'] as Map<String, dynamic>?;
    return Payment(
      method: json['method'] as String,
      status: json['status'] as String,
      amount: json['amount'] as int,
      bank: bank == null
          ? null
          : (
              bank: bank['bank'] as String,
              number: bank['number'] as String,
              holder: bank['holder'] as String,
            ),
      paidAt: DateTime.tryParse(json['paid_at'] as String? ?? ''),
    );
  }
}

class Shipment {
  final String? courier;
  final String? service;
  final String? trackingNumber;
  final String status;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;

  const Shipment({
    required this.courier,
    required this.service,
    required this.trackingNumber,
    required this.status,
    required this.shippedAt,
    required this.deliveredAt,
  });

  factory Shipment.fromJson(Map<String, dynamic> json) => Shipment(
        courier: json['courier'] as String?,
        service: json['service'] as String?,
        trackingNumber: json['tracking_number'] as String?,
        status: json['status'] as String,
        shippedAt: DateTime.tryParse(json['shipped_at'] as String? ?? ''),
        deliveredAt: DateTime.tryParse(json['delivered_at'] as String? ?? ''),
      );

  /// "JNE REG", atau "Kurir toko" untuk ongkir flat.
  String get courierLabel {
    final c = courier ?? '';
    if (c.isEmpty || c == 'toko') return 'Kurir toko';
    return [c.toUpperCase(), if (service != null) service].join(' ');
  }
}

class Order {
  final int id;
  final String orderNumber;
  final OrderStatus status;
  final DateTime createdAt;
  final int subtotal;
  final int shippingCost;
  final int discount;
  final int total;
  final String? notes;
  final ShippingAddress address;
  final List<OrderItem> items;
  final Payment? payment;
  final Shipment? shipment;

  const Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.createdAt,
    required this.subtotal,
    required this.shippingCost,
    required this.discount,
    required this.total,
    required this.notes,
    required this.address,
    required this.items,
    required this.payment,
    required this.shipment,
  });

  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);

  factory Order.fromJson(Map<String, dynamic> json) {
    final payment = json['payment'] as Map<String, dynamic>?;
    final shipment = json['shipment'] as Map<String, dynamic>?;
    return Order(
      id: json['id'] as int,
      orderNumber: json['order_number'] as String,
      status: OrderStatus.parse(json['status'] as String?),
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      subtotal: json['subtotal'] as int,
      shippingCost: json['shipping_cost'] as int,
      discount: (json['discount'] ?? 0) as int,
      total: json['total'] as int,
      notes: json['notes'] as String?,
      address: ShippingAddress.fromJson(json['shipping_address'] as Map<String, dynamic>),
      items: (json['items'] as List<dynamic>)
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      payment: payment == null ? null : Payment.fromJson(payment),
      shipment: shipment == null ? null : Shipment.fromJson(shipment),
    );
  }
}

/// Isi checkout yang dikirim ke `POST /api/orders`. Ongkir dihitung ulang di server.
class PlaceOrder {
  final int addressId;
  final String courier;
  final String service;
  final String bank;
  final String notes;

  const PlaceOrder({
    required this.addressId,
    required this.courier,
    required this.service,
    required this.bank,
    required this.notes,
  });

  Map<String, dynamic> toJson() => {
        'address_id': addressId,
        'courier': courier,
        'service': service,
        'payment_method': 'manual_transfer',
        'bank': bank,
        'notes': notes.trim().isEmpty ? null : notes.trim(),
      };
}
