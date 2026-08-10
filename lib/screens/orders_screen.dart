import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../services/api.dart';
import '../state/app_state.dart';
import '../utils/format.dart';
import 'kurir_tracking_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Order>? _orders;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final orders = await Api.orders();
      setState(() => _orders = orders);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pesanan Saya')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: (_orders == null || _orders!.isEmpty)
                  ? ListView(
                      children: const [
                        SizedBox(height: 120),
                        Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 12),
                        Center(child: Text('Belum ada pesanan')),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _orders!.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _OrderCard(order: _orders![i]),
                    ),
            ),
    );
  }
}

class _OrderCard extends StatefulWidget {
  final Order order;
  const _OrderCard({required this.order});

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _reordering = false;

  Order get order => widget.order;

  Color _statusColor(String s) {
    switch (s) {
      case 'baru':
        return Colors.blue;
      case 'diproses':
        return Colors.orange;
      case 'dikirim':
        return Colors.purple;
      case 'selesai':
        return Colors.green;
      case 'batal':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _beliLagi() async {
    if (_reordering) return;
    setState(() => _reordering = true);
    try {
      final app = context.read<AppState>();
      for (final item in order.items) {
        await app.addToCart(item.productId, qty: item.qty, varian: item.varian);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua item ditambahkan ke keranjang'), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _reordering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstItem = order.items.isNotEmpty ? order.items.first : null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shopping_bag_outlined, size: 16),
              const SizedBox(width: 6),
              Text('Belanja', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(width: 4),
              Text('• ${formatDate(order.createdAt)}', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: _statusColor(order.status).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(order.statusLabel, style: TextStyle(fontSize: 11, color: _statusColor(order.status), fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          if (order.statusKurir.isNotEmpty && order.status != 'batal') ...[
            const SizedBox(height: 4),
            Text('Kurir: ${order.statusKurir.toUpperCase()}', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          ],
          const Divider(height: 18),
          if (firstItem != null) ...[
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.shopping_bag, color: Colors.grey, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(firstItem.nama, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text('${firstItem.qty} barang x ${rupiah(firstItem.harga)}',
                          style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                      if (order.items.length > 1) ...[
                        const SizedBox(height: 2),
                        Text('+${order.items.length - 1} item lainnya', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
          const Divider(height: 18),
          Row(
            children: [
              Expanded(
                child: Text('Total Belanja', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ),
              Text(rupiah(order.total), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            ],
          ),
          if (order.statusKurir == 'perjalanan' || order.statusKurir == 'diambil') ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => KurirTrackingScreen(order: order),
                )),
                icon: const Icon(Icons.near_me),
                label: const Text('Lacak Kurir'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF171717), foregroundColor: Colors.white),
              ),
            ),
          ],
          if (order.status != 'batal' && order.items.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _reordering ? null : _beliLagi,
                icon: _reordering
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.replay),
                label: Text(_reordering ? 'Menambahkan...' : 'Beli Lagi'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF171717),
                  side: const BorderSide(color: Colors.black),                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
