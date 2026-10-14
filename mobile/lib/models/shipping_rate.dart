/// Satu pilihan layanan kurir dari `/api/shipping/rates`.
class ShippingRate {
  final String courier;
  final String courierName;
  final String service;
  final String description;
  final int cost;
  final String etd;

  const ShippingRate({
    required this.courier,
    required this.courierName,
    required this.service,
    required this.description,
    required this.cost,
    required this.etd,
  });

  /// Kurir toko = ongkir flat saat RajaOngkir belum dikonfigurasi.
  static const flatCourier = 'toko';

  /// "JNE REG", atau "Kurir toko".
  String get label =>
      courier == flatCourier ? courierName : '${courier.toUpperCase()} $service';

  /// "2-3 day" / "2-3 HARI" → "Estimasi 2–3 hari"; null bila tidak ada.
  String? get etdLabel {
    final days = etd.replaceAll(RegExp(r'[^0-9\-]'), '').replaceAll('-', '–');
    return days.isEmpty ? null : 'Estimasi $days hari';
  }

  bool sameAs(ShippingRate other) => courier == other.courier && service == other.service;

  factory ShippingRate.fromJson(Map<String, dynamic> json) => ShippingRate(
        courier: json['courier'] as String,
        courierName: json['courier_name'] as String,
        service: json['service'] as String,
        description: (json['description'] ?? '') as String,
        cost: json['cost'] as int,
        etd: (json['etd'] ?? '') as String,
      );
}
