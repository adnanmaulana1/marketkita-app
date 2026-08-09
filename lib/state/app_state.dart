import 'package:flutter/foundation.dart';

import '../models/cart.dart';
import '../models/user.dart';
import '../services/api.dart';

class AppState extends ChangeNotifier {
  User? _user;
  Cart? _cart;
  bool _loading = false;

  User? get user => _user;
  Cart? get cart => _cart;
  bool get loading => _loading;

  bool get isLoggedIn => _user != null;

  Future<void> load() async {
    await Api.init();
    final token = Api.token;
    if (token == null) {
      notifyListeners();
      return;
    }
    _loading = true;
    notifyListeners();
    try {
      _user = await Api.me();
    } catch (_) {
      await Api.clearToken();
      _user = null;
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _loading = true;
    notifyListeners();
    try {
      _user = await Api.login(email, password);
      _cart = await Api.cart();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String nama,
    required String email,
    required String telepon,
    required String password,
    required String role,
    String namaToko = '',
    String kendaraan = '',
  }) async {
    _loading = true;
    notifyListeners();
    try {
      _user = await Api.register(
        nama: nama,
        email: email,
        telepon: telepon,
        password: password,
        role: role,
        namaToko: namaToko,
        kendaraan: kendaraan,
      );
      if (role != 'toko' && role != 'kurir') {
        _cart = await Api.cart();
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await Api.logout();
    _user = null;
    _cart = null;
    notifyListeners();
  }

  Future<void> refreshCart() async {
    if (!isLoggedIn) return;
    _cart = await Api.cart();
    notifyListeners();
  }

  Future<void> addToCart(int productId, {int qty = 1, String varian = ''}) async {
    _cart = await Api.cartAdd(productId, qty: qty, varian: varian);
    notifyListeners();
  }

  Future<void> updateCart(int itemId, int qty) async {
    _cart = await Api.cartUpdate(itemId, qty);
    notifyListeners();
  }

  Future<void> removeCart(int itemId) async {
    _cart = await Api.cartRemove(itemId);
    notifyListeners();
  }

  Future<void> setUser(User u) {
    _user = u;
    notifyListeners();
    return Future.value();
  }

  Future<bool> favoritToggleApi(int productId) async {
    final fav = await Api.favoritToggle(productId);
    notifyListeners();
    return fav;
  }
}
