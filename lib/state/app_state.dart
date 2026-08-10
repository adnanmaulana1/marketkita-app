import 'package:flutter/foundation.dart';

import '../models/alamat_kirim.dart';
import '../models/cart.dart';
import '../models/user.dart';
import '../services/alamat_service.dart';
import '../services/api.dart';
import '../services/ws_service.dart';

class AppState extends ChangeNotifier {
  User? _user;
  Cart? _cart;
  bool _loading = false;
  int _chatUnread = 0;
  int _kurirOrderBaru = 0;
  final Set<int> _favoritIds = {};
  final List<void Function(Map<String, dynamic>)> _realtimeListeners = [];
  List<AlamatKirim> _alamatList = [];
  AlamatKirim? _alamatAktif;

  User? get user => _user;
  Cart? get cart => _cart;
  bool get loading => _loading;
  int get chatUnread => _chatUnread;
  int get kurirOrderBaru => _kurirOrderBaru;
  Set<int> get favoritIds => _favoritIds;
  List<AlamatKirim> get alamatList => _alamatList;
  AlamatKirim? get alamatAktif => _alamatAktif;

  bool get isLoggedIn => _user != null;

  /// Daftarkan listener global untuk event realtime (mis. kurir_order_baru).
  void onRealtime(void Function(Map<String, dynamic>) cb) {
    _realtimeListeners.add(cb);
  }

  void removeRealtimeListener(void Function(Map<String, dynamic>) cb) {
    _realtimeListeners.remove(cb);
  }

  void _notifyRealtime(Map<String, dynamic> data) {
    final type = data['type']?.toString();
    if (type == 'unread') {
      _chatUnread = (data['total'] as num?)?.toInt() ?? 0;
      notifyListeners();
      return;
    }
    if (type == 'kurir_order_baru') {
      _kurirOrderBaru++;
      notifyListeners();
      return;
    }
    for (final cb in List.of(_realtimeListeners)) {
      try {
        cb(data);
      } catch (_) {}
    }
  }

  void connectRealtime() {
    final ws = WsService.instance;
    ws.removeAll(_notifyRealtime);
    ws.listen(_notifyRealtime);
    ws.connect();
  }

  void disconnectRealtime() {
    final ws = WsService.instance;
    ws.removeAll(_notifyRealtime);
  }

  Future<void> load() async {
    await Api.init();
    await loadAlamat();
    final token = Api.token;
    if (token == null) {
      notifyListeners();
      return;
    }
    _loading = true;
    notifyListeners();
    try {
      _user = await Api.me();
      connectRealtime();
      await _refreshFavoritSilent();
    } on ApiException catch (e) {
      // Hanya hapus sesi bila token memang ditolak (401/403).
      // Error jaringan (timeout, server down) TIDAK menghapus token,
      // sehingga pengguna tidak "dikeluarkan" tanpa alasan.
      if (e.statusCode == 401 || e.statusCode == 403) {
        await Api.clearToken();
      }
      _user = null;
    } catch (_) {
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
      connectRealtime();
      await _refreshFavoritSilent();
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
  }) async {
    _loading = true;
    notifyListeners();
    try {
      _user = await Api.register(
        nama: nama,
        email: email,
        telepon: telepon,
        password: password,
        role: 'pembeli',
      );
      _cart = await Api.cart();
      connectRealtime();
      await _refreshFavoritSilent();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await Api.logout();
    disconnectRealtime();
    WsService.instance.disconnect();
    _user = null;
    _cart = null;
    _chatUnread = 0;
    _kurirOrderBaru = 0;
    _favoritIds.clear();
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

  Future<void> setUser(User u) async {
    _user = u;
    notifyListeners();
  }

  /// Muat ulang data user dari server (mis. setelah top-up / update profil).
  Future<void> refreshUser() async {
    if (!isLoggedIn) return;
    _user = await Api.me();
    notifyListeners();
  }

  /// Muat daftar alamat kirim dari perangkat.
  Future<void> loadAlamat() async {
    _alamatList = await AlamatService.list();
    final aktifId = await AlamatService.aktifId();
    _alamatAktif = null;
    for (final a in _alamatList) {
      if (a.id == aktifId) {
        _alamatAktif = a;
        break;
      }
    }
    if (_alamatAktif == null && _alamatList.isNotEmpty) {
      _alamatAktif = _alamatList.first;
    }
    notifyListeners();
  }

  /// Simpan alamat baru/perubahan lalu jadikan alamat aktif.
  Future<void> saveAlamat(AlamatKirim a) async {
    await AlamatService.save(a);
    await AlamatService.setAktifId(a.id);
    _alamatList = await AlamatService.list();
    _alamatAktif = a;
    notifyListeners();
  }

  /// Pilih alamat yang dipakai untuk pengiriman.
  Future<void> setAlamatAktif(AlamatKirim a) async {
    await AlamatService.setAktifId(a.id);
    _alamatAktif = a;
    notifyListeners();
  }

  /// Hapus alamat; bila yang aktif dihapus, fallback ke alamat pertama.
  Future<void> hapusAlamat(int id) async {
    await AlamatService.delete(id);
    _alamatList = await AlamatService.list();
    if (_alamatAktif?.id == id) {
      _alamatAktif = _alamatList.isNotEmpty ? _alamatList.first : null;
      if (_alamatAktif != null) {
        await AlamatService.setAktifId(_alamatAktif!.id);
      }
    }
    notifyListeners();
  }

  Future<void> _refreshFavoritSilent() async {
    try {
      await refreshFavorit();
    } catch (_) {}
  }

  /// Muat ulang daftar id produk favorit dari server.
  Future<void> refreshFavorit() async {
    if (!isLoggedIn) {
      _favoritIds.clear();
      notifyListeners();
      return;
    }
    final res = await Api.favorit();
    _favoritIds
      ..clear()
      ..addAll(res.products.map((p) => p.id));
    notifyListeners();
  }

  /// Toggle favorit: sinkron ke server lalu perbarui state lokal.
  Future<bool> toggleFavorite(int productId) async {
    final fav = await Api.favoritToggle(productId);
    if (fav) {
      _favoritIds.add(productId);
    } else {
      _favoritIds.remove(productId);
    }
    notifyListeners();
    return fav;
  }
}
