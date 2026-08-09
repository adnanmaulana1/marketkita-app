import 'package:flutter/material.dart';

import '../models/order.dart';
import '../services/api.dart';
import '../utils/format.dart';

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
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _OrderCard(order: _orders![i]),
                    ),
            ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  const _OrderCard({required this.order});

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

  @override
  Widget build(BuildContext context) {
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
              Text(order.nomor, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(width: 8),
              Text(formatDate(order.createdAt), style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: _statusColor(order.status).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(order.statusLabel, style: TextStyle(fontSize: 11, color: _statusColor(order.status), fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          if (order.statusKurir.isNotEmpty && order.status != 'batal') ...[
            const SizedBox(height: 4),
            Text('Kurir: ${order.statusKurir.toUpperCase()}', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          ],
          const Divider(height: 20),
          for (final item in order.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(child: Text(item.nama, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13))),
                  Text('${item.qty}x', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  const SizedBox(width: 8),
                  Text(rupiah(item.harga * item.qty), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          const Divider(height: 20),
          Row(
            children: [
              if (order.storeNama != null)
                Expanded(child: Text('${order.storeNama}', style: TextStyle(fontSize: 12, color: Colors.grey[600]))),
              const Spacer(),
              Text('Total: ', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              Text(rupiah(order.total), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }
}
