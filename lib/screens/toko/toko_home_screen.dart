import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../models/product.dart';
import '../../services/toko_api.dart';
import '../../state/app_state.dart';
import '../../utils/format.dart';
import '../chat_list_screen.dart';

class TokoHomeScreen extends StatefulWidget {
  const TokoHomeScreen({super.key});

  @override
  State<TokoHomeScreen> createState() => _TokoHomeScreenState();
}

class _TokoHomeScreenState extends State<TokoHomeScreen> {

  TokoDashboard? _data;
  bool _loading = true;
  String? _err;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final d = await TokoApi.dashboard();
      setState(() => _data = d);
    } catch (e) {
      setState(() => _err = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _ubahStatus(int orderId, String status) async {
    await TokoApi.ubahStatus(orderId, status);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Toko', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: app.chatUnread > 0,
              label: Text('${app.chatUnread}'),
              child: const Icon(Icons.chat_bubble_outline),
            ),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await app.logout();
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _err != null
              ? Center(child: Text('$_err'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _header(),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _statCard('${_data?.jumlahProduk ?? 0}', 'Produk', Icons.inventory_2_outlined)),
                          const SizedBox(width: 12),
                          Expanded(child: _statCard('${_data?.jumlahPesanan ?? 0}', 'Pesanan', Icons.receipt_long_outlined)),
                          const SizedBox(width: 12),
                          Expanded(child: _statCard(rupiah(_data?.store['saldo'] ?? 0), 'Saldo', Icons.account_balance_wallet_outlined)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text('Pesanan Terbaru', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 10),
                      if (_data!.orders.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Center(child: Text('Belum ada pesanan', style: TextStyle(color: Colors.grey[600]))),
                        )
                      else
                        ..._data!.orders.map((o) => _TokoOrderCard(order: o, onStatus: _ubahStatus)),
                      const SizedBox(height: 20),
                      const Text('Produk Saya', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 10),
                      ..._data!.products.map((p) => _ProductRow(product: p)),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _showAddProductSheet,
                        icon: const Icon(Icons.add),
                        label: const Text('Tambah Produk'),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF171717), foregroundColor: Colors.white),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _header() {
    final store = _data!.store;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF171717), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(store['nama'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('${store['kecamatan'] ?? ''} · ${store['kabupaten'] ?? ''}', style: TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF171717)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Future<void> _showAddProductSheet() async {
    final nama = TextEditingController();
    final harga = TextEditingController();
    final stok = TextEditingController();
    final deskripsi = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Tambah Produk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              TextField(controller: nama, decoration: const InputDecoration(labelText: 'Nama Produk', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: harga, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga (Rp)', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: stok, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stok', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: deskripsi, maxLines: 2, decoration: const InputDecoration(labelText: 'Deskripsi', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final h = int.tryParse(harga.text) ?? 0;
                  final s = int.tryParse(stok.text) ?? 0;
                  if (nama.text.trim().isEmpty || h <= 0) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lengkapi nama & harga')));
                    return;
                  }
                  await TokoApi.tambahProduk(nama: nama.text.trim(), harga: h, stok: s, deskripsi: deskripsi.text.trim());
                  if (mounted) Navigator.pop(context);
                  await _load();
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF171717), foregroundColor: Colors.white),
                child: const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TokoOrderCard extends StatelessWidget {
  final Order order;
  final void Function(int orderId, String status) onStatus;
  const _TokoOrderCard({required this.order, required this.onStatus});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(order.nomor, style: const TextStyle(fontWeight: FontWeight.w800)),
              const Spacer(),
              Text(order.statusLabel, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
          const Divider(height: 16),
          for (final it in order.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(child: Text(it.nama, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13))),
                  Text('${it.qty}x', style: TextStyle(color: Colors.grey[500])),
                  const SizedBox(width: 8),
                  Text(rupiah(it.harga * it.qty), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('Total ${rupiah(order.total)}', style: const TextStyle(fontWeight: FontWeight.w800)),
              const Spacer(),
              Text(order.metodeBayar, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
          const SizedBox(height: 10),
          if (order.status == 'baru')
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => onStatus(order.id, 'diproses'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                    child: const Text('Proses'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => onStatus(order.id, 'batal'),
                    child: const Text('Batalkan'),
                  ),
                ),
              ],
            )
          else if (order.status == 'diproses')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => onStatus(order.id, 'dikirim'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
                child: const Text('Tandai Dikirim'),
              ),
            )
          else if (order.status == 'dikirim')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => onStatus(order.id, 'selesai'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                child: const Text('Tandai Selesai'),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  final Product product;
  const _ProductRow({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 48,
              height: 48,
              child: product.gambarUrl.isEmpty
                  ? Container(color: Colors.grey[200], child: const Icon(Icons.image, color: Colors.grey))
                  : Image.network(product.gambarUrl.first, fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                          color: Colors.grey[200], child: const Icon(Icons.image, color: Colors.grey))),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.nama, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(rupiah(product.harga), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                Text('Stok ${product.stok}', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: product.isActive ? Colors.green.shade50 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(product.isActive ? 'Aktif' : 'Nonaktif',
                style: TextStyle(fontSize: 11, color: product.isActive ? Colors.green.shade700 : Colors.grey[600])),
          ),
        ],
      ),
    );
  }
}
