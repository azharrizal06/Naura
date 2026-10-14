/// Hasil pencarian kecamatan/kelurahan RajaOngkir (`/api/shipping/destinations`).
class Destination {
  final int id;
  final String label;
  final String? subdistrict;
  final String? district;
  final String? city;
  final String? province;
  final String? postalCode;

  const Destination({
    required this.id,
    required this.label,
    required this.subdistrict,
    required this.district,
    required this.city,
    required this.province,
    required this.postalCode,
  });

  factory Destination.fromJson(Map<String, dynamic> json) => Destination(
        id: json['id'] as int,
        label: json['label'] as String,
        subdistrict: json['subdistrict'] as String?,
        district: json['district'] as String?,
        city: json['city'] as String?,
        province: json['province'] as String?,
        postalCode: json['postal_code'] as String?,
      );
}
