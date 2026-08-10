import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/api.dart';
import '../../state/app_state.dart';
import '../../utils/format.dart';
import '../location_picker_screen.dart';

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
  double _lat = 0;
  double _lng = 0;
  String _locLabel = '';
  List<Map<String, dynamic>> _vouchers = [];
  int _voucherId = 0;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    final u = app.user;
    _nama.text = u?.nama ?? '';
    _telepon.text = u?.telepon ?? '';
    _loadVouchers();
  }

  Future<void> _loadVouchers() async {
    try {
      final res = await Api.vouchers();
      if (!mounted) return;
      setState(() {
        _vouchers = res.mine
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .where((m) => m['status'] == 'belum')
            .toList();
      });
    } catch (_) {}
  }

  int get _subtotal => context.read<AppState>().cart?.subtotal ?? 0;

  Map<String, dynamic>? get _selectedVoucher {
    if (_voucherId == 0) return null;
    for (final v in _vouchers) {
      if ((v['id'] as num?)?.toInt() == _voucherId) return v;
    }
    return null;
  }

  String _voucherDesc(String tipe, int nilai) {
    if (tipe == 'persen') return '$nilai%';
    if (tipe == 'ongkir') return 'Gratis ongkir';
    return rupiah(nilai);
  }

  /// Estimasi diskon voucher (belum termasuk pengiriman/ongkir).
  int get _estDiskon {
    final v = _selectedVoucher;
    if (v == null) return 0;
    final tipe = v['tipe'] as String? ?? '';
    final nilai = (v['nilai'] as num?)?.toInt() ?? 0;
    if (tipe == 'persen') {
      final d = _subtotal * nilai ~/ 100;
      return d > _subtotal ? _subtotal : d;
    }
    if (tipe == 'ongkir') return 0;
    return nilai > _subtotal ? _subtotal : nilai;
  }

  Future<void> _pickLocation() async {
    final res = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => LocationPickerScreen()),
    );
    if (res != null && mounted) {
      setState(() {
        _lat = (res['lat'] as num).toDouble();
        _lng = (res['lng'] as num).toDouble();
        _locLabel = res['label'] as String? ?? '';
      });
      if (_alamat.text.trim().isEmpty && _locLabel.isNotEmpty) {
        _alamat.text = _locLabel;
      }
    }
  }

  Future<void> _submit() async {
    final app = context.read<AppState>();
    if (app.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silakan login terlebih dahulu')));
      Navigator.pushNamed(context, '/login');
      return;
    }
    if (_nama.text.trim().isEmpty || _telepon.text.trim().isEmpty || _alamat.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lengkapi nama, telepon, dan alamat')));
      return;
    }
    if (_shipping == 'kurir_lokal' && _lat == 0 && _lng == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih titik lokasi di peta untuk kurir lokal')));
      return;
    }
    if (_pembayaran == 'saldo') {
      final saldo = app.user!.saldo;
      if (_subtotal > saldo) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saldo dompet tidak cukup. Saldo: ${rupiah(saldo)}')),
        );
        return;
      }
    }
    setState(() => _submitting = true);
    try {
      // Pakai seluruh saldo bila memungkinkan; backend akan memotong
      // maksimal min(saldo, total pesanan). Sisa dibayar COD saat kurir tiba.
      final pakaiSaldo = _pembayaran == 'saldo' ? (app.user?.saldo ?? 0) : 0;
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
        voucherId: _voucherId,
        pakaiSaldo: pakaiSaldo,
        bayarSisa: 'cod',
        lat: _lat,
        lng: _lng,
      );
      await app.refreshCart();
      await app.refreshUser();
      if (!mounted) return;
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
    final u = app.user;

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
            InkWell(
              onTap: _pickLocation,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Pilih Lokasi di Peta',
                  border: const OutlineInputBorder(),
                  suffixIcon: const Icon(Icons.map_outlined),
                  errorText: _shipping == 'kurir_lokal' && _lat == 0 && _lng == 0 ? 'Wajib pilih lokasi untuk kurir lokal' : null,
                ),
                child: Text(
                  _locLabel.isNotEmpty
                      ? _locLabel
                      : (_lat != 0 && _lng != 0
                          ? '${_lat.toStringAsFixed(5)}, ${_lng.toStringAsFixed(5)}'
                          : 'Ketuk untuk memilih titik di peta'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
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
            RadioGroup<String>(
              groupValue: _shipping,
              onChanged: (v) => setState(() => _shipping = v ?? 'ambil_toko'),
              child: const Column(
                children: [
                  RadioListTile<String>(
                    value: 'ambil_toko',
                    title: Text('Ambil di Toko'),
                    subtitle: Text('Gratis'),
                  ),
                  RadioListTile<String>(
                    value: 'kurir_lokal',
                    title: Text('Kurir Lokal (Ojek)'),
                    subtitle: Text('Dihitung dari jarak'),
                  ),
                  RadioListTile<String>(
                    value: 'ekspedisi',
                    title: Text('Ekspedisi (JNE / J&T)'),
                    subtitle: Text('Rp15.000'),
                  ),
                ],
              ),
            ),
          ]),
          _section('Metode Pembayaran', [
            RadioGroup<String>(
              groupValue: _pembayaran,
              onChanged: (v) => setState(() => _pembayaran = v ?? 'cod'),
              child: Column(
                children: [
                  const RadioListTile<String>(value: 'cod', title: Text('COD / Tunai')),
                  const RadioListTile<String>(value: 'transfer', title: Text('Transfer Bank')),
                  const RadioListTile<String>(value: 'ewallet', title: Text('E-Wallet')),
                  const RadioListTile<String>(value: 'qris', title: Text('QRIS')),
                  RadioListTile<String>(
                    value: 'saldo',
                    title: const Text('Saldo Dompet'),
                    subtitle: u != null ? Text('Saldo tersedia: ${rupiah(u.saldo)}') : null,
                  ),
                ],
              ),
            ),
          ]),
          if (_vouchers.isNotEmpty)
            _section('Voucher', [
              RadioGroup<int>(
                groupValue: _voucherId,
                onChanged: (v) => setState(() => _voucherId = v ?? 0),
                child: Column(
                  children: [
                    RadioListTile<int>(
                      value: 0,
                      title: const Text('Tanpa voucher'),
                      dense: true,
                    ),
                    for (final v in _vouchers)
                      RadioListTile<int>(
                        value: (v['id'] as num?)?.toInt() ?? 0,
                        title: Text(
                          '${v['nama']} — ${_voucherDesc(v['tipe'] as String? ?? '', (v['nilai'] as num?)?.toInt() ?? 0)}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        subtitle: Text(
                          'Min. belanja ${rupiah((v['min_belanja'] as num?)?.toInt() ?? 0)}',
                          style: const TextStyle(fontSize: 11),
                        ),
                        dense: true,
                        enabled: subtotal >= ((v['min_belanja'] as num?)?.toInt() ?? 0),
                      ),
                  ],
                ),
              ),
            ]),
          _section('Catatan', [
            TextField(controller: _catatan, maxLines: 2, decoration: const InputDecoration(hintText: 'Catatan untuk penjual (opsional)', border: OutlineInputBorder())),
          ]),
          const SizedBox(height: 8),
          _section('Ringkasan', [
            _row('Subtotal', rupiah(subtotal)),
            _row('Ongkir', _shipping == 'ambil_toko' ? 'Gratis' : 'Dihitung otomatis'),
            if (_selectedVoucher != null) _row('Diskon voucher', '-${rupiah(_estDiskon)}'),
            const Divider(height: 20),
            _row('Total yang dibayar', rupiah(subtotal - _estDiskon), emphasized: true),
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

  Widget _row(String k, String v, {bool emphasized = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: TextStyle(color: Colors.grey[600], fontWeight: emphasized ? FontWeight.w800 : null)),
          Text(v, style: TextStyle(fontWeight: FontWeight.w700, fontSize: emphasized ? 18 : null)),
        ],
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
