/// Format angka rupiah sederhana tanpa dependensi intl.
/// Contoh: 1500000 -> "Rp1.500.000"
String formatRupiah(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(digits[i]);
  }
  final sign = value < 0 ? '-' : '';
  return 'Rp$sign$buffer';
}

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

/// Contoh: 13 Okt 2026
String formatDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

const _keepUpper = {'DKI', 'DI', 'NTB', 'NTT'};

/// "SUMUR BANDUNG" → "Sumur Bandung"; singkatan seperti DKI tetap kapital.
String titleCase(String text) => text
    .split(RegExp(r'\s+'))
    .where((w) => w.isNotEmpty)
    .map((w) => _keepUpper.contains(w.toUpperCase())
        ? w.toUpperCase()
        : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
    .join(' ');
