import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../services/kurir_api.dart';
import '../../state/app_state.dart';
import '../../utils/format.dart';

class KurirHomeScreen extends StatefulWidget {
  const KurirHomeScreen({super.key});

  @override
  State<KurirHomeScreen> createState() => _KurirHomeScreenState();
}

class _KurirHomeScreenState extends State<KurirHomeScreen> {

  KurirDashboard? _data;
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
      final d = await KurirApi.dashboard();
      setState(() => _data = d);
    } catch (e) {
      setState(() => _err = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _do(String action, int orderId, {String status = ''}) async {
    try {
      switch (action) {
        case 'ambil':
          await KurirApi.ambil(orderId);
          break;
        case 'status':
          await KurirApi.ubahStatus(orderId, status);
          break;
        case 'batal':
          await KurirApi.batal(orderId);
          break;
      }
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Kurir', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await app.logout();
              if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _err != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$_err', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _load, child: const Text('Coba lagi')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _header(),
                      const SizedBox(height: 16),
                      _saldoCard(),
                      const SizedBox(height: 20),
                      if (_data!.saya.isNotEmpty) ...[
                        const Text('Tugas Aktif', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 10),
                        ..._data!.saya.map((o) => _OrderCard(order: o, isMine: true, onAction: _do)),
                        const SizedBox(height: 20),
                      ],
                      const Text('Pesanan Tersedia', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 10),
                      if (_data!.tersedia.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            children: [
                              Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 8),
                              Text('Tidak ada pesanan tersedia', style: TextStyle(color: Colors.grey[600])),
                            ],
                          ),
                        )
                      else
                        ..._data!.tersedia.map((o) => _OrderCard(order: o, isMine: false, onAction: _do)),
                      const SizedBox(height: 20),
                      if (_data!.riwayat.isNotEmpty) ...[
                        const Text('Riwayat Diantar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 10),
                        ..._data!.riwayat.map((o) => _OrderCard(order: o, isMine: false, onAction: _do)),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _header() {
    final u = context.read<AppState>().user;
    return Row(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: Colors.grey[300],
          child: const Icon(Icons.two_wheeler),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(u?.nama ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              Text('Kurir${u?.kendaraan.isNotEmpty == true ? ' · ${u!.kendaraan}' : ''}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20)),
          child: Text('${_data?.totalDiantar ?? 0} diantar', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w700, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _saldoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF171717), Color(0xFF333333)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 32),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Saldo', style: TextStyle(color: Colors.white70, fontSize: 12)),
              Text(rupiah(_data?.saldo ?? 0), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
            ],
          ),
          const Spacer(),
          OutlinedButton(
            onPressed: () => _showTarikSheet(),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54)),
            child: const Text('Tarik'),
          ),
        ],
      ),
    );
  }

  Future<void> _showTarikSheet() async {
    final ctl = TextEditingController();
    final saldo = _data?.saldo ?? 0;
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
              const Text('Penarikan Saldo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Text('Saldo tersedia: ${rupiah(saldo)}', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 12),
              TextField(
                controller: ctl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Nominal', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final n = int.tryParse(ctl.text) ?? 0;
                  if (n <= 0 || n > saldo) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nominal tidak valid')));
                    return;
                  }
                  await KurirApi.tarik(n);
                  if (mounted) Navigator.pop(context);
                  await _load();
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF171717), foregroundColor: Colors.white),
                child: const Text('Tarik Saldo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final bool isMine;
  final void Function(String action, int orderId, {String status}) onAction;
  const _OrderCard({required this.order, required this.isMine, required this.onAction});

  Color _kurirColor(String s) {
    switch (s) {
      case 'menunggu':
        return Colors.green;
      case 'diambil':
        return Colors.blue;
      case 'perjalanan':
        return Colors.orange;
      case 'diantar':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final kc = _kurirColor(order.statusKurir);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(order.nomor, style: const TextStyle(fontWeight: FontWeight.w800)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: kc.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(order.statusKurir.toUpperCase(), style: TextStyle(fontSize: 11, color: kc, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.storefront, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(child: Text(order.storeNama ?? '-', style: const TextStyle(fontWeight: FontWeight.w600))),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${order.namaPenerima} — ${order.alamat}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          for (final it in order.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(child: Text(it.nama, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13))),
                  Text('${it.qty}x', style: TextStyle(color: Colors.grey[500])),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total ${rupiah(order.total)}', style: const TextStyle(fontWeight: FontWeight.w800)),
              Text('Ongkir ${rupiah(order.ongkir)}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
          const SizedBox(height: 12),
          if (order.statusKurir == 'menunggu' && !isMine)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => onAction('ambil', order.id),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF171717), foregroundColor: Colors.white),
                child: const Text('Ambil Order'),
              ),
            )
          else if (isMine && order.statusKurir == 'diambil')
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => onAction('status', order.id, status: 'perjalanan'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                    child: const Text('Mulai Perjalanan'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => onAction('batal', order.id),
                  child: const Text('Batal'),
                ),
              ],
            )
          else if (isMine && order.statusKurir == 'perjalanan')
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => onAction('status', order.id, status: 'diantar'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    child: const Text('Tandai Sudah Diantar'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => onAction('batal', order.id),
                  child: const Text('Batal'),
                ),
              ],
            )
          else if (order.statusKurir == 'diantar')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(10)),
              child: Text('Selesai diantar', textAlign: TextAlign.center, style: TextStyle(color: Colors.teal.shade700, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}
