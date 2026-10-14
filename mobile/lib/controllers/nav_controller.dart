import 'package:flutter/foundation.dart';

enum NavTab { catalog, cart, orders, account }

/// Tab aktif di navigasi bawah; layar lain bisa berpindah tab lewat [go].
class NavController extends ChangeNotifier {
  NavTab _tab = NavTab.catalog;

  NavTab get tab => _tab;

  void go(NavTab tab) {
    if (tab == _tab) return;
    _tab = tab;
    notifyListeners();
  }
}
