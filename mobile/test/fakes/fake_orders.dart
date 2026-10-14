import 'package:naura_mobile/models/order.dart';
import 'package:naura_mobile/services/api_client.dart';
import 'package:naura_mobile/services/order_service.dart';

Map<String, dynamic> orderJson({int id = 1, String status = 'pending'}) => {
      'id': id,
      'order_number': 'INV-20261013-000$id',
      'status': status,
      'created_at': '2026-10-13T10:00:00.000000Z',
      'subtotal': 578000,
      'shipping_cost': 15000,
      'discount': 0,
      'total': 593000,
      'notes': null,
      'shipping_address': {
        'recipient_name': 'Budi Customer',
        'phone': '081200000003',
        'address_line': 'Jl. Merdeka 1',
        'city': 'Bandung',
        'province': 'Jawa Barat',
        'postal_code': '40111',
      },
      'items': [
        {
          'id': 10,
          'product_name': 'Gamis Ceruti Alesha',
          'variant_name': 'Mocca / L',
          'unit_price': 289000,
          'quantity': 2,
          'subtotal': 578000,
          'product': {'id': 3, 'slug': 'gamis-ceruti-alesha', 'primary_image': null},
        }
      ],
      'payment': {
        'method': 'manual_transfer',
        'status': status == 'pending' ? 'pending' : 'paid',
        'amount': 593000,
        'bank': {'bank': 'BCA', 'number': '1234567890', 'holder': 'Toko Naura'},
        'paid_at': null,
      },
      'shipment': {
        'courier': 'jne',
        'service': 'REG',
        'tracking_number': status == 'shipped' ? 'JNE123' : null,
        'status': status == 'shipped' ? 'shipped' : 'preparing',
        'shipped_at': status == 'shipped' ? '2026-10-14T08:00:00.000000Z' : null,
        'delivered_at': null,
      },
    };

class FakeOrderService implements OrderService {
  ApiException? error;
  PlaceOrder? lastPlaced;

  @override
  Future<List<Order>> list() async {
    if (error != null) throw error!;
    return [Order.fromJson(orderJson(id: 2)), Order.fromJson(orderJson(id: 1, status: 'shipped'))];
  }

  @override
  Future<Order> find(int id) async {
    if (error != null) throw error!;
    return Order.fromJson(orderJson(id: id));
  }

  @override
  Future<Order> place(PlaceOrder request) async {
    if (error != null) throw error!;
    lastPlaced = request;
    return Order.fromJson(orderJson(id: 9));
  }
}
