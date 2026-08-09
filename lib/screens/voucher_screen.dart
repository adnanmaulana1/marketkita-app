import 'package:flutter/material.dart';

import '../models/voucher.dart';
import '../services/api.dart';
import '../utils/format.dart';

class VoucherScreen extends StatefulWidget {
  const VoucherScreen({super.key});

  @override
  State<VoucherScreen> createState() => _VoucherScreenState();
}

class _VoucherScreenState extends State<VoucherScreen> {
  List<Voucher>? _available;
  List<dynamic> _mine = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await Api.vouchers();
      setState(() {
        _available = res.available;
        _mine = res.mine;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _klaim(String kode) async {
    try {
      final msg = await Api.klaimVoucher(kode);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Voucher')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Voucher Tersedia', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 10),
                if (_available == null || _available!.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('Tidak ada voucher tersedia', style: TextStyle(color: Colors.grey[600]))),
                  )
                else
                  ..._available!.map((v) => _VoucherCard(voucher: v, onKlaim: () => _klaim(v.kode))),
                const SizedBox(height: 24),
                const Text('Voucher Saya', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 10),
                if (_mine.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('Belum ada voucher diklaim', style: TextStyle(color: Colors.grey[600]))),
                  )
                else
                  ..._mine.map((m) => ListTile(
                        leading: const Icon(Icons.confirmation_number),
                        title: Text('${m['nama']}'),
                        subtitle: Text('${m['kode']} · ${m['status']}'),
                        trailing: Text(_voucherDesc(m['tipe'], m['nilai']), style: const TextStyle(fontWeight: FontWeight.w700)),
                      )),
              ],
            ),
    );
  }

  String _voucherDesc(String tipe, int nilai) {
    if (tipe == 'persen') return '$nilai%';
    if (tipe == 'ongkir') return 'Ongkir';
    return rupiah(nilai);
  }
}

class _VoucherCard extends StatelessWidget {
  final Voucher voucher;
  final VoidCallback onKlaim;
  const _VoucherCard({required this.voucher, required this.onKlaim});

  String get _desc {
    if (voucher.tipe == 'persen') return 'Diskon ${voucher.nilai}%';
    if (voucher.tipe == 'ongkir') return 'Gratis ongkir';
    return 'Potongan ${rupiah(voucher.nilai)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFF171717), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.local_offer, color: Colors.white),
        ),
        title: Text('${voucher.nama} — $_desc', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        subtitle: Text(
          'Min. belanja ${rupiah(voucher.minBelanja)}'
          '${voucher.berlakuSampai != null ? ' · s/d ${formatDate(voucher.berlakuSampai, withTime: false)}' : ''}',
          style: const TextStyle(fontSize: 11),
        ),
        trailing: TextButton(
          onPressed: onKlaim,
          child: const Text('Klaim'),
        ),
      ),
    );
  }
}
