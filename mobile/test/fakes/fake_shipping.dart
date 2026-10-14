import 'package:naura_mobile/models/address.dart';
import 'package:naura_mobile/models/destination.dart';
import 'package:naura_mobile/models/shipping_rate.dart';
import 'package:naura_mobile/services/address_service.dart';
import 'package:naura_mobile/services/api_client.dart';
import 'package:naura_mobile/services/shipping_service.dart';

Address address({int id = 1, bool isDefault = true, String label = 'Rumah', int? destinationId = 17473}) =>
    Address(
      id: id,
      label: label,
      recipientName: 'Budi Customer',
      phone: '081200000003',
      addressLine: 'Jl. Merdeka 1',
      subdistrict: 'Braga',
      district: 'Sumur Bandung',
      city: 'Bandung',
      province: 'Jawa Barat',
      postalCode: '40111',
      destinationId: destinationId,
      isDefault: isDefault,
    );

const jneReg = ShippingRate(
  courier: 'jne',
  courierName: 'JNE',
  service: 'REG',
  description: 'Reguler',
  cost: 18000,
  etd: '2-3 day',
);

const jntEz = ShippingRate(
  courier: 'jnt',
  courierName: 'J&T Express',
  service: 'EZ',
  description: 'Reguler',
  cost: 16000,
  etd: '2-4 day',
);

class FakeAddressService implements AddressService {
  final List<Address> items = [];
  ApiException? error;
  int _nextId = 10;

  @override
  Future<List<Address>> list() async {
    if (error != null) throw error!;
    return List.of(items);
  }

  @override
  Future<Address> create(Address draft) async {
    if (error != null) throw error!;
    final saved = draft.copyWith(id: _nextId++, isDefault: draft.isDefault || items.isEmpty);
    if (saved.isDefault) {
      for (var i = 0; i < items.length; i++) {
        items[i] = items[i].copyWith(isDefault: false);
      }
    }
    items.add(saved);
    return saved;
  }

  @override
  Future<Address> update(Address address) async {
    if (error != null) throw error!;
    final i = items.indexWhere((a) => a.id == address.id);
    items[i] = address;
    return address;
  }

  @override
  Future<void> delete(int id) async {
    if (error != null) throw error!;
    items.removeWhere((a) => a.id == id);
  }
}

class FakeShippingService implements ShippingService {
  List<ShippingRate> available = [jneReg, jntEz];
  ApiException? ratesError;
  ApiException? searchError;
  final List<int> rateRequests = [];
  final List<String> searches = [];

  @override
  Future<List<Destination>> searchDestinations(String query) async {
    searches.add(query);
    if (searchError != null) throw searchError!;
    return const [
      Destination(
        id: 17473,
        label: 'BRAGA, SUMUR BANDUNG, BANDUNG, JAWA BARAT, 40111',
        subdistrict: 'BRAGA',
        district: 'SUMUR BANDUNG',
        city: 'BANDUNG',
        province: 'JAWA BARAT',
        postalCode: '40111',
      ),
    ];
  }

  @override
  Future<List<ShippingRate>> rates(int addressId) async {
    rateRequests.add(addressId);
    if (ratesError != null) throw ratesError!;
    return available;
  }
}
