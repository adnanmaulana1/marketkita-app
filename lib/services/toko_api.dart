import '../models/order.dart';
import '../models/product.dart';
import '../models/voucher.dart';
import 'api.dart';

class TokoDashboard {
  final Map<String, dynamic> store;
  final int jumlahProduk;
  final int jumlahPesanan;
  final List<Order> orders;
  final List<Product> products;

  TokoDashboard({
    required this.store,
    required this.jumlahProduk,
    required this.jumlahPesanan,
    required this.orders,
    required this.products,
  });
}

class TokoApi {
  static Future<TokoDashboard> dashboard() async {
    final res = await Api.get('/api/toko/dashboard');
    return TokoDashboard(
      store: (res['store'] as Map).cast<String, dynamic>(),
      jumlahProduk: (res['jumlah_produk'] as num?)?.toInt() ?? 0,
      jumlahPesanan: (res['jumlah_pesanan'] as num?)?.toInt() ?? 0,
      orders: (res['orders'] as List).map((e) => Order.fromJson(e)).toList(),
      products: (res['products'] as List).map((e) => Product.fromJson(e)).toList(),
    );
  }

  static Future<List<Order>> orders() async {
    final res = await Api.get('/api/toko/orders');
    return (res['orders'] as List).map((e) => Order.fromJson(e)).toList();
  }

  static Future<Order> ubahStatus(int orderId, String status) async {
    final res = await Api.post('/api/toko/orders/$orderId/status', {'status': status});
    return Order.fromJson(res['order']);
  }

  static Future<List<Product>> products() async {
    final res = await Api.get('/api/toko/products');
    return (res['products'] as List).map((e) => Product.fromJson(e)).toList();
  }

  static Future<Product> tambahProduk({
    required String nama,
    required int harga,
    required int stok,
    int kategoriId = 1,
    String deskripsi = '',
  }) async {
    final res = await Api.post('/api/toko/products', {
      'nama': nama,
      'harga': '$harga',
      'stok': '$stok',
      'kategori_id': '$kategoriId',
      'deskripsi': deskripsi,
    });
    return Product.fromJson(res['product']);
  }

  static Future<Product> updateProduk(int productId, {required String nama, required int harga, required int stok, String deskripsi = '', int isActive = 1}) async {
    final res = await Api.post('/api/toko/products/$productId/update', {
      'nama': nama,
      'harga': '$harga',
      'stok': '$stok',
      'deskripsi': deskripsi,
      'is_active': '$isActive',
    });
    return Product.fromJson(res['product']);
  }

  static Future<void> hapusProduk(int productId) async {
    await Api.post('/api/toko/products/$productId/hapus', {});
  }

  static Future<({int saldo, List<Transaksi> transaksi})> saldo() async {
    final res = await Api.get('/api/toko/saldo');
    return (
      saldo: (res['saldo'] as num?)?.toInt() ?? 0,
      transaksi: (res['transaksi'] as List).map((e) => Transaksi.fromJson(e)).toList(),
    );
  }

  static Future<int> tarik(int nominal) async {
    final res = await Api.post('/api/toko/saldo/tarik', {'nominal': '$nominal'});
    return (res['saldo'] as num?)?.toInt() ?? 0;
  }
}
