import 'package:flutter_test/flutter_test.dart';

import 'package:naura_mobile/models/cart.dart';

void main() {
  test('Cart.fromJson membaca respons GET /api/cart', () {
    final cart = Cart.fromJson({
      'items': [
        {
          'id': 7,
          'variant_id': 12,
          'variant_name': 'Mocca / L',
          'product': {
            'id': 3,
            'name': 'Gamis Ceruti Alesha',
            'slug': 'gamis-ceruti-alesha',
            'primary_image': null,
          },
          'unit_price': 289000,
          'quantity': 2,
          'stock': 10,
          'line_total': 578000,
        }
      ],
      'count': 2,
      'subtotal': 578000,
      'shipping_cost': 15000,
      'total': 593000,
    });

    final item = cart.items.single;
    expect(item.id, 7);
    expect(item.variantId, 12);
    expect(item.productName, 'Gamis Ceruti Alesha');
    expect(item.lineTotal, 578000);
    expect(cart.count, 2);
    expect(cart.shippingCost, 15000);
    expect(cart.total, 593000);
  });

  test('Cart.empty tidak berisi apa pun', () {
    expect(Cart.empty.isEmpty, isTrue);
    expect(Cart.empty.total, 0);
  });
}
