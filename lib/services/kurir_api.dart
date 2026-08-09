import '../models/order.dart';
import '../models/voucher.dart';
import 'api.dart';

class KurirDashboard {
  final int saldo;
  final int totalDiantar;
  final List<Order> tersedia;
  final List<Order> saya;
  final List<Order> riwayat;

  KurirDashboard({
    required this.saldo,
    required this.totalDiantar,
    required this.tersedia,
    required this.saya,
    required this.riwayat,
  });
}

class KurirApi {
  static Future<KurirDashboard> dashboard() async {
    final res = await Api.get('/api/kurir/dashboard');
    return KurirDashboard(
      saldo: (res['saldo'] as num?)?.toInt() ?? 0,
      totalDiantar: (res['total_diantar'] as num?)?.toInt() ?? 0,
      tersedia: (res['tersedia'] as List).map((e) => Order.fromJson(e)).toList(),
      saya: (res['saya'] as List).map((e) => Order.fromJson(e)).toList(),
      riwayat: (res['riwayat'] as List).map((e) => Order.fromJson(e)).toList(),
    );
  }

  static Future<Order> ambil(int orderId) async {
    final res = await Api.post('/api/kurir/ambil/$orderId', {});
    return Order.fromJson(res['order']);
  }

  static Future<Order> ubahStatus(int orderId, String status) async {
    final res = await Api.post('/api/kurir/order/$orderId/status', {'status': status});
    return Order.fromJson(res['order']);
  }

  static Future<Order> batal(int orderId) async {
    final res = await Api.post('/api/kurir/order/$orderId/batal', {});
    return Order.fromJson(res['order']);
  }

  static Future<({int saldo, int pendapatan, List<Transaksi> transaksi})> saldo() async {
    final res = await Api.get('/api/kurir/saldo');
    return (
      saldo: (res['saldo'] as num?)?.toInt() ?? 0,
      pendapatan: (res['pendapatan'] as num?)?.toInt() ?? 0,
      transaksi: (res['transaksi'] as List).map((e) => Transaksi.fromJson(e)).toList(),
    );
  }

  static Future<int> tarik(int nominal) async {
    final res = await Api.post('/api/kurir/saldo/tarik', {'nominal': '$nominal'});
    return (res['saldo'] as num?)?.toInt() ?? 0;
  }
}
