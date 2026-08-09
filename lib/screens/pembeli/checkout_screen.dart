import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/api.dart';
import '../../state/app_state.dart';
import '../../utils/format.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _nama = TextEditingController();
  final _telepon = TextEditingController();
  final _provinsi = TextEditingController(text: 'Sulawesi Barat');
  final _kota = TextEditingController(text: 'Polewali Mandar');
  final _kecamatan = TextEditingController(text: 'Polewali');
  final _kodePos = TextEditingController(text: '91311');
  final _alamat = TextEditingController();
  final _catatan = TextEditingController();
  String _shipping = 'kurir_lokal';
  String _pembayaran = 'cod';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    final u = app.user;
    _nama.text = u?.nama ?? '';
    _telepon.text = u?.telepon ?? '';
  }

  Future<void> _submit() async {
    if (_nama.text.trim().isEmpty || _telepon.text.trim().isEmpty || _alamat.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lengkapi nama, telepon, dan alamat')));
      return;
    }
    setState(() => _submitting = true);
    try {
      final ids = await Api.checkout(
        nama: _nama.text.trim(),
        telepon: _telepon.text.trim(),
        provinsi: _provinsi.text.trim(),
        kota: _kota.text.trim(),
        kecamatan: _kecamatan.text.trim(),
        kodePos: _kodePos.text.trim(),
        alamat: _alamat.text.trim(),
        catatan: _catatan.text.trim(),
        shipping: _shipping,
        pembayaran: _pembayaran,
      );
      if (!mounted) return;
      final app = context.read<AppState>();
      await app.refreshCart();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => _SuccessScreen(orderIds: ids)),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final cart = app.cart;
    final subtotal = cart?.subtotal ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('Alamat Penerima', [
            TextField(controller: _nama, decoration: const InputDecoration(labelText: 'Nama Penerima', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _telepon, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Telepon', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _alamat, maxLines: 2, decoration: const InputDecoration(labelText: 'Alamat Lengkap', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextField(controller: _kecamatan, decoration: const InputDecoration(labelText: 'Kecamatan', border: OutlineInputBorder(), isDense: true))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: _kodePos, decoration: const InputDecoration(labelText: 'Kode Pos', border: OutlineInputBorder(), isDense: true))),
              ],
            ),
          ]),
          _section('Metode Pengiriman', [
            RadioListTile<String>(
              value: 'ambil_toko',
              groupValue: _shipping,
              onChanged: (v) => setState(() => _shipping = v!),
              title: const Text('Ambil di Toko'),
              subtitle: const Text('Gratis'),
            ),
            RadioListTile<String>(
              value: 'kurir_lokal',
              groupValue: _shipping,
              onChanged: (v) => setState(() => _shipping = v!),
              title: const Text('Kurir Lokal (Ojek)'),
              subtitle: const Text('Dihitung dari jarak'),
            ),
            RadioListTile<String>(
              value: 'ekspedisi',
              groupValue: _shipping,
              onChanged: (v) => setState(() => _shipping = v!),
              title: const Text('Ekspedisi (JNE / J&T)'),
              subtitle: const Text('Rp15.000'),
            ),
          ]),
          _section('Metode Pembayaran', [
            RadioListTile<String>(value: 'cod', groupValue: _pembayaran, onChanged: (v) => setState(() => _pembayaran = v!), title: const Text('COD / Tunai')),
            RadioListTile<String>(value: 'transfer', groupValue: _pembayaran, onChanged: (v) => setState(() => _pembayaran = v!), title: const Text('Transfer Bank')),
            RadioListTile<String>(value: 'ewallet', groupValue: _pembayaran, onChanged: (v) => setState(() => _pembayaran = v!), title: const Text('E-Wallet')),
            RadioListTile<String>(value: 'qris', groupValue: _pembayaran, onChanged: (v) => setState(() => _pembayaran = v!), title: const Text('QRIS')),
            RadioListTile<String>(value: 'saldo', groupValue: _pembayaran, onChanged: (v) => setState(() => _pembayaran = v!), title: const Text('Saldo Dompet')),
          ]),
          _section('Catatan', [
            TextField(controller: _catatan, maxLines: 2, decoration: const InputDecoration(hintText: 'Catatan untuk penjual (opsional)', border: OutlineInputBorder())),
          ]),
          const SizedBox(height: 8),
          _section('Ringkasan', [
            _row('Subtotal', rupiah(subtotal)),
            _row('Ongkir', _shipping == 'ambil_toko' ? 'Gratis' : 'Dihitung otomatis'),
          ]),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade200))),
          child: ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF171717),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _submitting
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Buat Pesanan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(k, style: TextStyle(color: Colors.grey[600])), Text(v, style: const TextStyle(fontWeight: FontWeight.w700))],
      ),
    );
  }
}

class _SuccessScreen extends StatelessWidget {
  final List<int> orderIds;
  const _SuccessScreen({required this.orderIds});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 80),
              const SizedBox(height: 16),
              const Text('Pesanan Berhasil Dibuat!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('${orderIds.length} pesanan telah dibuat.', style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF171717), foregroundColor: Colors.white),
                child: const Text('Kembali ke Beranda'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
