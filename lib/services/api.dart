import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../models/cart.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../models/user.dart';
import '../models/voucher.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class Api {
  static const _prefsToken = 'auth_token';
  static String? _token;

  static String? get token => _token;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_prefsToken);
  }

  static Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsToken, token);
  }

  static Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsToken);
  }

  static Uri _uri(String path, [Map<String, String>? query]) {
    final base = Uri.parse(AppConfig.baseUrl);
    var u = base.resolve(path);
    if (query != null && query.isNotEmpty) {
      u = u.replace(queryParameters: {...u.queryParameters, ...query});
    }
    return u;
  }

  static Map<String, String> _headers({bool json = false}) {
    final h = <String, String>{'Accept': 'application/json'};
    if (_token != null) h['Authorization'] = 'Bearer $_token';
    if (json) h['Content-Type'] = 'application/json';
    return h;
  }

  static dynamic _decode(http.Response res) {
    dynamic data;
    try {
      data = jsonDecode(res.body);
    } catch (_) {
      throw ApiException('Respons tidak valid dari server (${res.statusCode})');
    }
    return data;
  }

  static Map<String, dynamic> _check(http.Response res) {
    final data = _decode(res);
    if (res.statusCode >= 400) {
      final msg = (data is Map && data['msg'] != null) ? data['msg'].toString() : 'Terjadi kesalahan (${res.statusCode})';
      throw ApiException(msg);
    }
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
  }

  // Generic helpers (dipakai modul lain)
  static Future<Map<String, dynamic>> get(String path) async {
    final res = await http.get(_uri(path), headers: _headers());
    return _check(res);
  }

  static Future<Map<String, dynamic>> post(String path, Map<String, String> body) async {
    final res = await http.post(_uri(path), headers: _headers(), body: body);
    return _check(res);
  }

  // ===== AUTH =====
  static Future<User> login(String email, String password) async {
    final res = await http.post(_uri('/api/auth/login'), body: {'email': email, 'password': password});
    final d = _check(res);
    await saveToken(d['token'] as String);
    return User.fromJson(d['user']);
  }

  static Future<User> register({
    required String nama,
    required String email,
    required String telepon,
    required String password,
    required String role,
    String namaToko = '',
    String kendaraan = '',
  }) async {
    final res = await http.post(
      _uri('/api/auth/register'),
      body: {
        'nama': nama,
        'email': email,
        'telepon': telepon,
        'password': password,
        'role': role,
        'nama_toko': namaToko,
        'kendaraan': kendaraan,
      },
    );
    final d = _check(res);
    await saveToken(d['token'] as String);
    return User.fromJson(d['user']);
  }

  static Future<User> me() async {
    final res = await http.get(_uri('/api/auth/me'), headers: _headers());
    final d = _check(res);
    return User.fromJson(d['user']);
  }

  static Future<void> logout() async => clearToken();

  // ===== KATALOG =====
  static Future<List<Category>> categories() async {
    final res = await http.get(_uri('/api/categories'), headers: _headers());
    final d = _check(res);
    return (d['categories'] as List).map((e) => Category.fromJson(e)).toList();
  }

  static Future<({List<Product> products, int total, int pages})> products({
    String kategori = '',
    String q = '',
    String toko = '',
    String sort = '',
    int page = 1,
  }) async {
    final res = await http.get(
      _uri('/api/products', {
        if (kategori.isNotEmpty) 'kategori': kategori,
        if (q.isNotEmpty) 'q': q,
        if (toko.isNotEmpty) 'toko': toko,
        if (sort.isNotEmpty) 'sort': sort,
        'page': '$page',
      }),
      headers: _headers(),
    );
    final d = _check(res);
    return (
      products: (d['products'] as List).map((e) => Product.fromJson(e)).toList(),
      total: (d['total'] as num?)?.toInt() ?? 0,
      pages: (d['pages'] as num?)?.toInt() ?? 1,
    );
  }

  static Future<Product> productDetail(int id) async {
    final res = await http.get(_uri('/api/products/$id'), headers: _headers());
    final d = _check(res);
    return Product.fromJson(d['product']);
  }

  // ===== FAVORIT =====
  static Future<({List<Product> products, List<Map<String, dynamic>> stores})> favorit() async {
    final res = await http.get(_uri('/api/favorit'), headers: _headers());
    final d = _check(res);
    return (
      products: (d['products'] as List).map((e) => Product.fromJson(e)).toList(),
      stores: (d['stores'] as List).cast<Map<String, dynamic>>(),
    );
  }

  static Future<bool> favoritToggle(int productId) async {
    final res = await http.post(_uri('/api/favorit/$productId'), headers: _headers());
    final d = _check(res);
    return d['favorited'] as bool? ?? false;
  }

  // ===== KERANJANG =====
  static Future<Cart> cart() async {
    final res = await http.get(_uri('/api/keranjang'), headers: _headers());
    final d = _check(res);
    return Cart.fromJson(d['cart']);
  }

  static Future<Cart> cartAdd(int productId, {int qty = 1, String varian = ''}) async {
    final res = await http.post(_uri('/api/keranjang'),
        headers: _headers(), body: {'product_id': '$productId', 'qty': '$qty', 'varian': varian});
    final d = _check(res);
    return Cart.fromJson(d['cart']);
  }

  static Future<Cart> cartUpdate(int itemId, int qty) async {
    final res = await http.post(_uri('/api/keranjang/ubah'),
        headers: _headers(), body: {'item_id': '$itemId', 'qty': '$qty'});
    final d = _check(res);
    return Cart.fromJson(d['cart']);
  }

  static Future<Cart> cartRemove(int itemId) async {
    final res = await http.post(_uri('/api/keranjang/hapus'),
        headers: _headers(), body: {'item_id': '$itemId'});
    final d = _check(res);
    return Cart.fromJson(d['cart']);
  }

  // ===== CHECKOUT =====
  static Future<List<int>> checkout({
    required String nama,
    required String telepon,
    required String provinsi,
    required String kota,
    required String kecamatan,
    required String kodePos,
    required String alamat,
    String catatan = '',
    String shipping = 'ambil_toko',
    String pembayaran = 'cod',
    int voucherId = 0,
    double lat = 0,
    double lng = 0,
  }) async {
    final res = await http.post(_uri('/api/checkout'), headers: _headers(), body: {
      'nama': nama,
      'telepon': telepon,
      'provinsi': provinsi,
      'kota': kota,
      'kecamatan': kecamatan,
      'kode_pos': kodePos,
      'alamat': alamat,
      'catatan': catatan,
      'shipping': shipping,
      'pembayaran': pembayaran,
      'voucher_id': '$voucherId',
      'lat': '$lat',
      'lng': '$lng',
    });
    final d = _check(res);
    return (d['order_ids'] as List).map((e) => (e as num).toInt()).toList();
  }

  // ===== PESANAN =====
  static Future<List<Order>> orders() async {
    final res = await http.get(_uri('/api/orders'), headers: _headers());
    final d = _check(res);
    return (d['orders'] as List).map((e) => Order.fromJson(e)).toList();
  }

  static Future<Order> orderDetail(int id) async {
    final res = await http.get(_uri('/api/orders/$id'), headers: _headers());
    final d = _check(res);
    return Order.fromJson(d['order']);
  }

  // ===== VOUCHER =====
  static Future<({List<Voucher> available, List<dynamic> mine})> vouchers() async {
    final res = await http.get(_uri('/api/vouchers'), headers: _headers());
    final d = _check(res);
    return (
      available: (d['available'] as List).map((e) => Voucher.fromJson(e)).toList(),
      mine: (d['mine'] as List).toList(),
    );
  }

  static Future<String> klaimVoucher(String kode) async {
    final res = await http.post(_uri('/api/vouchers/klaim'),
        headers: _headers(), body: {'kode': kode});
    final d = _check(res);
    return d['msg'] as String? ?? 'Berhasil diklaim';
  }

  // ===== SALDO =====
  static Future<({int saldo, List<Transaksi> transaksi})> saldo() async {
    final res = await http.get(_uri('/api/saldo'), headers: _headers());
    final d = _check(res);
    return (
      saldo: (d['saldo'] as num?)?.toInt() ?? 0,
      transaksi: (d['transaksi'] as List).map((e) => Transaksi.fromJson(e)).toList(),
    );
  }

  static Future<int> topup(int nominal) async {
    final res = await http.post(_uri('/api/saldo/topup'), headers: _headers(), body: {'nominal': '$nominal'});
    final d = _check(res);
    return (d['saldo'] as num?)?.toInt() ?? 0;
  }

  // ===== PROFIL =====
  static Future<User> updateProfil({String nama = '', String telepon = '', String passwordLama = '', String passwordBaru = ''}) async {
    final res = await http.post(_uri('/api/profil'), headers: _headers(), body: {
      'nama': nama,
      'telepon': telepon,
      'password_lama': passwordLama,
      'password_baru': passwordBaru,
    });
    final d = _check(res);
    return User.fromJson(d['user']);
  }
}
