import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:naura_mobile/controllers/auth_controller.dart';
import 'package:naura_mobile/screens/splash_screen.dart';
import 'package:naura_mobile/services/api_client.dart';
import 'package:naura_mobile/services/auth_service.dart';

void main() {
  testWidgets('Menampilkan loading saat status auth belum diketahui',
      (WidgetTester tester) async {
    final authService = AuthService(ApiClient());

    await tester.pumpWidget(
      ChangeNotifierProvider(
        // Tidak memanggil bootstrap() agar status tetap `unknown`.
        create: (_) => AuthController(authService),
        child: const MaterialApp(home: SplashScreen()),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
