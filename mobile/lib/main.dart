import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'controllers/address_controller.dart';
import 'controllers/auth_controller.dart';
import 'controllers/cart_controller.dart';
import 'controllers/catalog_controller.dart';
import 'controllers/nav_controller.dart';
import 'controllers/orders_controller.dart';
import 'screens/splash_screen.dart';
import 'services/address_service.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/cart_service.dart';
import 'services/catalog_service.dart';
import 'services/order_service.dart';
import 'services/shipping_service.dart';
import 'theme/naura_theme.dart';

void main() {
  final apiClient = ApiClient();

  runApp(NauraApp(
    authService: AuthService(apiClient),
    catalogService: CatalogService(apiClient),
    cartService: CartService(apiClient),
    orderService: OrderService(apiClient),
    addressService: AddressService(apiClient),
    shippingService: ShippingService(apiClient),
  ));
}

class NauraApp extends StatelessWidget {
  const NauraApp({
    super.key,
    required this.authService,
    required this.catalogService,
    required this.cartService,
    required this.orderService,
    required this.addressService,
    required this.shippingService,
  });

  final AuthService authService;
  final CatalogService catalogService;
  final CartService cartService;
  final OrderService orderService;
  final AddressService addressService;
  final ShippingService shippingService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController(authService)..bootstrap()),
        ChangeNotifierProvider(create: (_) => CatalogController(catalogService)),
        ChangeNotifierProvider(create: (_) => CartController(cartService)),
        ChangeNotifierProvider(create: (_) => OrdersController(orderService)),
        ChangeNotifierProvider(create: (_) => NavController()),
        ChangeNotifierProvider(create: (_) => AddressController(addressService)),
        Provider<CatalogService>.value(value: catalogService),
        Provider<OrderService>.value(value: orderService),
        Provider<ShippingService>.value(value: shippingService),
      ],
      child: MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: buildNauraTheme(),
        home: const SplashScreen(),
      ),
    );
  }
}
