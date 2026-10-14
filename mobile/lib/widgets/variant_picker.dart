import 'package:flutter/material.dart';

import '../models/product.dart';
import '../models/variant_options.dart';
import '../theme/naura_theme.dart';
import '../utils/swatch.dart';

/// Pemilih varian. Nama "Warna / Ukuran" tampil sebagai swatch warna kain
/// dan kotak ukuran; nama tanpa warna dikenal tampil sebagai pilihan biasa.
class VariantPicker extends StatelessWidget {
  const VariantPicker({
    super.key,
    required this.variants,
    required this.selected,
    required this.onSelect,
  });

  final List<ProductVariant> variants;
  final ProductVariant? selected;
  final ValueChanged<ProductVariant> onSelect;

  @override
  Widget build(BuildContext context) {
    final options = VariantOptions(variants);
    if (!options.usesColors) return _plainOptions();

    final (selColor, selSize) =
        selected != null ? splitVariant(selected!.name) : (options.colors.first, null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _OptionLabel(title: 'Warna', value: selColor),
        const SizedBox(height: 12),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            for (final c in options.colors)
              _SwatchButton(
                name: c,
                color: swatchFor(c)!,
                selected: c == selColor,
                available: options.colorAvailable(c),
                onTap: () {
                  final v = options.variantForColor(c, keepSize: selSize);
                  if (v != null) onSelect(v);
                },
              ),
          ],
        ),
        if (options.sizes.isNotEmpty) ...[
          const SizedBox(height: 24),
          _OptionLabel(title: 'Ukuran', value: selSize ?? ''),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final s in options.sizes)
                _SizeButton(
                  label: s,
                  selected: s == selSize,
                  available: options.find(selColor, s)?.inStock ?? false,
                  onTap: () {
                    final v = options.find(selColor, s);
                    if (v != null) onSelect(v);
                  },
                ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        _StockNote(variant: selected),
      ],
    );
  }

  Widget _plainOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _OptionLabel(title: 'Pilihan', value: selected?.name ?? ''),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final v in variants)
              _SizeButton(
                label: v.name,
                selected: v.id == selected?.id,
                available: v.inStock,
                onTap: () => onSelect(v),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _StockNote(variant: selected),
      ],
    );
  }
}

class _OptionLabel extends StatelessWidget {
  const _OptionLabel({required this.title, required this.value});
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(children: [
        TextSpan(text: '$title  ', style: const TextStyle(fontWeight: FontWeight.w700)),
        TextSpan(text: value, style: const TextStyle(color: NauraColors.muted)),
      ]),
      style: const TextStyle(fontSize: 14),
    );
  }
}

class _StockNote extends StatelessWidget {
  const _StockNote({required this.variant});
  final ProductVariant? variant;

  @override
  Widget build(BuildContext context) {
    final v = variant;
    if (v == null) return const SizedBox.shrink();
    if (!v.inStock) {
      return const Text('Habis untuk pilihan ini. Coba warna atau ukuran lain.',
          style: TextStyle(fontSize: 13, color: NauraColors.marun));
    }
    if (v.stock < 5) {
      return Text('Tinggal ${v.stock} lagi',
          style: const TextStyle(
              fontSize: 13, color: NauraColors.kuningan, fontWeight: FontWeight.w600));
    }
    return const SizedBox.shrink();
  }
}

/// Bulatan kain. Terpilih: cincin terong. Habis: dicoret diagonal.
class _SwatchButton extends StatelessWidget {
  const _SwatchButton({
    required this.name,
    required this.color,
    required this.selected,
    required this.available,
    required this.onTap,
  });

  final String name;
  final Color color;
  final bool selected;
  final bool available;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: available ? name : '$name, habis',
      selected: selected,
      button: true,
      child: Tooltip(
        message: name,
        child: InkResponse(
          onTap: onTap,
          radius: 28,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? NauraColors.terong : Colors.transparent,
                width: 2,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: NauraColors.terong.withValues(alpha: 0.15)),
              ),
              child: available
                  ? null
                  : CustomPaint(
                      painter: _StrikePainter(
                        isLightFabric(color) ? NauraColors.terong : Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StrikePainter extends CustomPainter {
  _StrikePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(size.width * 0.2, size.height * 0.8),
        Offset(size.width * 0.8, size.height * 0.2), paint);
  }

  @override
  bool shouldRepaint(_StrikePainter old) => old.color != color;
}

class _SizeButton extends StatelessWidget {
  const _SizeButton({
    required this.label,
    required this.selected,
    required this.available,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool available;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected
        ? Colors.white
        : available
            ? NauraColors.terong
            : NauraColors.muted.withValues(alpha: 0.6);
    return Semantics(
      label: available ? label : '$label, habis',
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          constraints: const BoxConstraints(minWidth: 52),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? NauraColors.terong : Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: selected ? NauraColors.terong : NauraColors.garisKuat),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w600,
              decoration: available ? null : TextDecoration.lineThrough,
            ),
          ),
        ),
      ),
    );
  }
}
