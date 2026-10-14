import 'package:flutter/material.dart';

/// Kosakata warna busana muslimah → warna kain.
/// Salinan tabel ini juga ada di dashboard/src/lib/swatch.ts — jaga tetap sama.
const Map<String, Color> fabricColors = {
  'broken white': Color(0xFFEEE8DC),
  'dusty pink': Color(0xFFD2A3A3),
  'dusty blue': Color(0xFF8EA3B8),
  'cokelat susu': Color(0xFFB08A6E),
  'hitam': Color(0xFF1F1A20),
  'putih': Color(0xFFFAF9F6),
  'abu': Color(0xFF9C9AA1),
  'navy': Color(0xFF24304F),
  'maroon': Color(0xFF6C1F2B),
  'marun': Color(0xFF6C1F2B),
  'mocca': Color(0xFFA07E62),
  'milo': Color(0xFF8A6A57),
  'coksu': Color(0xFFB08A6E),
  'cokelat': Color(0xFF6A4834),
  'coklat': Color(0xFF6A4834),
  'taro': Color(0xFFB6A2C8),
  'lilac': Color(0xFFC7B5DC),
  'lavender': Color(0xFFC9C0E3),
  'sage': Color(0xFFA2B299),
  'army': Color(0xFF5A5D3B),
  'olive': Color(0xFF76743F),
  'mustard': Color(0xFFC89E39),
  'emerald': Color(0xFF2E6D59),
  'tosca': Color(0xFF3D9A98),
  'mint': Color(0xFFBEDACA),
  'biru': Color(0xFF3C69A6),
  'denim': Color(0xFF4E698B),
  'merah': Color(0xFFB03838),
  'salem': Color(0xFFE6A48E),
  'peach': Color(0xFFEFBE9F),
  'nude': Color(0xFFD8B89F),
  'krem': Color(0xFFE9DEC7),
  'cream': Color(0xFFE9DEC7),
  'khaki': Color(0xFFBEAE83),
  'ungu': Color(0xFF6B4989),
  'hijau': Color(0xFF4D7949),
  'kuning': Color(0xFFE2BF4A),
  'oranye': Color(0xFFD8783A),
  'terracotta': Color(0xFFB45F3E),
};

final List<String> _keys = fabricColors.keys.toList()
  ..sort((a, b) => b.length.compareTo(a.length));

/// Warna kain pertama yang disebut dalam nama varian; null jika tidak ada.
Color? swatchFor(String variantName) {
  final lower = variantName.toLowerCase();
  for (final key in _keys) {
    if (lower.contains(key)) return fabricColors[key];
  }
  return null;
}

/// "Mocca / L" → ("Mocca", "L"); "Taro" → ("Taro", null).
(String, String?) splitVariant(String variantName) {
  final parts = variantName.split('/');
  final color = parts.first.trim();
  final size = parts.length > 1 ? parts.sublist(1).join('/').trim() : null;
  return (color, size == null || size.isEmpty ? null : size);
}

/// Apakah warna kain terang (butuh garis tepi / tanda gelap di atasnya).
bool isLightFabric(Color c) => c.computeLuminance() > 0.6;
