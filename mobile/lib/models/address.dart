/// Alamat pengiriman tersimpan (`/api/addresses`).
class Address {
  final int id;
  final String label;
  final String recipientName;
  final String phone;
  final String addressLine;
  final String? subdistrict;
  final String? district;
  final String city;
  final String province;
  final String postalCode;

  /// ID tujuan RajaOngkir; null bila diisi manual (ongkir kurir tidak bisa dihitung).
  final int? destinationId;
  final bool isDefault;

  const Address({
    required this.id,
    required this.label,
    required this.recipientName,
    required this.phone,
    required this.addressLine,
    required this.subdistrict,
    required this.district,
    required this.city,
    required this.province,
    required this.postalCode,
    required this.destinationId,
    required this.isDefault,
  });

  /// "Braga, Sumur Bandung, Bandung, Jawa Barat 40111"
  String get areaLine {
    final parts = [subdistrict, district, city, province]
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .join(', ');
    return '$parts $postalCode';
  }

  factory Address.fromJson(Map<String, dynamic> json) => Address(
        id: json['id'] as int,
        label: json['label'] as String,
        recipientName: json['recipient_name'] as String,
        phone: json['phone'] as String,
        addressLine: json['address_line'] as String,
        subdistrict: json['subdistrict'] as String?,
        district: json['district'] as String?,
        city: json['city'] as String,
        province: json['province'] as String,
        postalCode: json['postal_code'] as String,
        destinationId: json['destination_id'] as int?,
        isDefault: (json['is_default'] ?? false) as bool,
      );

  Map<String, dynamic> toJson() => {
        'label': label,
        'recipient_name': recipientName,
        'phone': phone,
        'address_line': addressLine,
        'subdistrict': subdistrict,
        'district': district,
        'city': city,
        'province': province,
        'postal_code': postalCode,
        'destination_id': destinationId,
        'is_default': isDefault,
      };

  Address copyWith({int? id, String? label, bool? isDefault}) => Address(
        id: id ?? this.id,
        label: label ?? this.label,
        recipientName: recipientName,
        phone: phone,
        addressLine: addressLine,
        subdistrict: subdistrict,
        district: district,
        city: city,
        province: province,
        postalCode: postalCode,
        destinationId: destinationId,
        isDefault: isDefault ?? this.isDefault,
      );
}
