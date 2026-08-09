import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../services/api.dart';
import '../../state/app_state.dart';
import '../../utils/format.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Product? _product;
  bool _loading = true;
  int _qty = 1;
  String _varian = '';
  int _currentImage = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await Api.productDetail(widget.productId);
      setState(() {
        _product = p;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _addToCart() async {
    final app = context.read<AppState>();
    if (!app.isLoggedIn) {
      Navigator.pushNamed(context, '/login');
      return;
    }
    try {
      await app.addToCart(_product!.id, qty: _qty, varian: _varian);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ditambahkan ke keranjang')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _buyNow() async {
    final app = context.read<AppState>();
    if (!app.isLoggedIn) {
      Navigator.pushNamed(context, '/login');
      return;
    }
    await _addToCart();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final p = _product!;
    final varianKeys = p.varian.keys.toList();

    return Scaffold(
      appBar: AppBar(title: Text(p.nama, maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          // Gallery
          SizedBox(
            height: 320,
            child: p.gambarUrl.isEmpty
                ? Container(color: Colors.grey[200], child: const Icon(Icons.image, size: 64, color: Colors.grey))
                : Stack(
                    children: [
                      PageView.builder(
                        itemCount: p.gambarUrl.length,
                        onPageChanged: (i) => setState(() => _currentImage = i),
                        itemBuilder: (_, i) => Image.network(
                          p.gambarUrl[i],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.image, size: 64, color: Colors.grey),
                          ),
                        ),
                      ),
                      if (p.gambarUrl.length > 1)
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                            child: Text('${_currentImage + 1}/${p.gambarUrl.length}',
                                style: const TextStyle(color: Colors.white, fontSize: 12)),
                          ),
                        ),
                      if (p.hasDiskon)
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [Colors.red.shade600, Colors.orange.shade500]),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('-${p.diskonPersen}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                          ),
                        ),
                    ],
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.kategori.toUpperCase(), style: TextStyle(fontSize: 11, letterSpacing: 1.2, color: Colors.grey[500], fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(p.nama, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1.3)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text('${p.rating}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(width: 6),
                    Text('· ${p.terjual} terjual', style: TextStyle(color: Colors.grey[600])),
                    const SizedBox(width: 10),
                    if (p.stok > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20)),
                        child: Text('Stok ${p.stok}', style: TextStyle(fontSize: 12, color: Colors.green.shade700)),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(20)),
                        child: Text('Stok Habis', style: TextStyle(fontSize: 12, color: Colors.red.shade700)),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rupiah(p.harga), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                      if (p.hasDiskon)
                        Text(rupiah(p.hargaCoret),
                            style: TextStyle(fontSize: 14, color: Colors.grey[400], decoration: TextDecoration.lineThrough)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 16,
                        runSpacing: 4,
                        children: [
                          _feature(Icons.local_shipping_outlined, 'Gratis ongkir area Polewali'),
                          _feature(Icons.verified_outlined, 'Pedagang terverifikasi'),
                          _feature(Icons.replay_outlined, 'Retur mudah 7 hari'),
                        ],
                      ),
                    ],
                  ),
                ),
                if (varianKeys.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  for (final key in varianKeys) ...[
                    Text(key, style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: (p.varian[key] as List).map<Widget>((val) {
                        final selected = _varian == val.toString();
                        return ChoiceChip(
                          label: Text(val.toString()),
                          selected: selected,
                          onSelected: (_) => setState(() => _varian = val.toString()),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Jumlah', style: TextStyle(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    _qtyStepper(),
                  ],
                ),
                const SizedBox(height: 20),
                Text('Deskripsi', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(p.deskripsi.isEmpty ? 'Tidak ada deskripsi.' : p.deskripsi,
                    style: TextStyle(color: Colors.grey[700], height: 1.5)),
                if (p.toko.nama.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.storefront),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.toko.nama, style: const TextStyle(fontWeight: FontWeight.w700)),
                              if (p.toko.alamat != null) Text(p.toko.alamat!, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: p.stok > 0 ? _buyNow : null,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Beli'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: p.stok > 0 ? _addToCart : null,
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Tambah ke Keranjang'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF171717),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _feature(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF171717)),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
      ],
    );
  }

  Widget _qtyStepper() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 16),
            onPressed: _qty > 1 ? () => setState(() => _qty--) : null,
          ),
          Text('$_qty', style: const TextStyle(fontWeight: FontWeight.w700)),
          IconButton(
            icon: const Icon(Icons.add, size: 16),
            onPressed: () => setState(() => _qty++),
          ),
        ],
      ),
    );
  }
}
