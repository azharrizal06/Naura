import 'package:flutter_test/flutter_test.dart';

import 'package:naura_mobile/controllers/nav_controller.dart';

void main() {
  test('mulai di tab Koleksi dan berpindah lewat go', () {
    final nav = NavController();
    expect(nav.tab, NavTab.catalog);

    var notified = 0;
    nav.addListener(() => notified++);
    nav.go(NavTab.orders);
    nav.go(NavTab.orders);

    expect(nav.tab, NavTab.orders);
    expect(notified, 1);
  });
}
