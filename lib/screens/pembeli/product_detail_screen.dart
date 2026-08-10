import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../services/api.dart';
import '../../state/app_state.dart';
import '../../utils/format.dart';
import 'checkout_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;
  final Product? initialProduct;
  const ProductDetailScreen({super.key, required this.productId, this.initialProduct});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Product? _product;
  bool _loading = true;
  int _qty = 1;
  String _varian = '';
  bool _actionLoading = false;
  bool _favLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialProduct != null) {
      _product = widget.initialProduct;
      _loading = false;
      _load(silent: true);
    } else {
      _load();
    }
  }

  Future<void> _load({bool silent = false}) async {
    try {
      final p = await Api.productDetail(widget.productId);
      if (!mounted) return;
      for (final u in p.gambarUrl) {
        try {
          await precacheImage(CachedNetworkImageProvider(u), context);
        } catch (_) {}
      }
      setState(() {
        _product = p;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
      setState(() => _loading = false);
    }
  }

  Future<void> _addToCart() async {
    if (_actionLoading) return;
    final app = context.read<AppState>();
    if (!app.isLoggedIn) {
      Navigator.pushNamed(context, '/login');
      return;
    }
    setState(() => _actionLoading = true);
    try {
      await app.addToCart(_product!.id, qty: _qty, varian: _varian);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ditambahkan ke keranjang')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _buyNow() async {
    if (_actionLoading) return;
    final app = context.read<AppState>();
    if (!app.isLoggedIn) {
      Navigator.pushNamed(context, '/login');
      return;
    }
    setState(() => _actionLoading = true);
    try {
      await app.addToCart(_product!.id, qty: _qty, varian: _varian);
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen()));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _toggleFavorit() async {
    if (_favLoading) return;
    final app = context.read<AppState>();
    if (!app.isLoggedIn) {
      Navigator.pushNamed(context, '/login');
      return;
    }
    setState(() => _favLoading = true);
    try {
      final fav = await app.toggleFavorite(_product!.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(fav ? 'Ditambahkan ke favorit' : 'Dihapus dari favorit'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal mengubah favorit')));
      }
    } finally {
      if (mounted) setState(() => _favLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showSkeleton = _loading && _product == null;
    final p = _product;
    final app = context.watch<AppState>();
    final isFav = p != null && app.favoritIds.contains(p.id);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: p == null
            ? null
            : Text(p.nama, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        actions: [
          if (p != null)
            IconButton(
              icon: _favLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.red : Colors.black87),
              onPressed: _toggleFavorit,
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.03), end: Offset.zero).animate(anim),
            child: child,
          ),
        ),
        child: showSkeleton ? const _DetailSkeleton(key: ValueKey('skeleton')) : _body(p!),
      ),
      bottomNavigationBar: showSkeleton
          ? null
          : TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              builder: (context, v, child) => Opacity(
                opacity: v,
                child: Transform.translate(offset: Offset(0, 18 * (1 - v)), child: child),
              ),
              child: _bottomBar(p!),
            ),
    );
  }

  Widget _body(Product p) {
    final varianKeys = p.varian.keys.toList();
    return ListView(
      key: const ValueKey('body'),
      padding: const EdgeInsets.only(bottom: 110),
      physics: const BouncingScrollPhysics(),
      children: [
        _GallerySection(product: p),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _priceBlock(p),
              const SizedBox(height: 16),
              _metaRow(p),
              if (varianKeys.isNotEmpty) ...[
                const SizedBox(height: 20),
                for (final key in varianKeys) ...[
                  Text(key, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (p.varian[key] as List).map<Widget>((val) {
                      final selected = _varian == val.toString();
                      return _varianChip(val.toString(), selected);
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
              _qtyRow(),
              const SizedBox(height: 20),
              _descriptionCard(p),
              if (p.toko.nama.isNotEmpty) ...[
                const SizedBox(height: 16),
                _storeCard(p),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _priceBlock(Product p) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.kategori.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, letterSpacing: 1.2, color: Colors.grey[500], fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text(p.nama, maxLines: 3, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, height: 1.3)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (p.hasDiskon)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF03AC0E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('HEMAT ${p.diskonPersen}%',
                      style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w900)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(rupiah(p.harga), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
          if (p.hasDiskon) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                Text(rupiah(p.hargaCoret),
                    style: TextStyle(fontSize: 14, color: Colors.grey[400], decoration: TextDecoration.lineThrough)),
                const SizedBox(width: 8),
                Icon(Icons.arrow_downward, size: 12, color: Colors.green.shade600),
                Text(' ${rupiah((p.hargaCoret ?? p.harga) - p.harga)}', style: TextStyle(fontSize: 12, color: Colors.green.shade700, fontWeight: FontWeight.w700)),
              ],
            ),
          ],
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 18,
            runSpacing: 8,
            children: [
              _feature(Icons.local_shipping_outlined, 'Gratis ongkir area Polewali'),
              _feature(Icons.verified_outlined, 'Pedagang terverifikasi'),
              _feature(Icons.replay_outlined, 'Retur mudah 7 hari'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metaRow(Product p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.star, color: Colors.amber, size: 20),
          const SizedBox(width: 4),
          Text('${p.rating}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(width: 6),
          Text('· ${p.terjual} terjual', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          const Spacer(),
          if (p.stok > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 13, color: Colors.green.shade600),
                  const SizedBox(width: 4),
                  Text('Stok ${p.stok}', style: TextStyle(fontSize: 12, color: Colors.green.shade700, fontWeight: FontWeight.w700)),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(20)),
              child: Text('Stok Habis', style: TextStyle(fontSize: 12, color: Colors.red.shade700, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }

  Widget _varianChip(String label, bool selected) {
    return GestureDetector(
      onTap: () => setState(() => _varian = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF03AC0E) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? const Color(0xFF03AC0E) : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _qtyRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Text('Jumlah', style: TextStyle(fontWeight: FontWeight.w700)),
          const Spacer(),
          _qtyStepper(),
        ],
      ),
    );
  }

  Widget _descriptionCard(Product p) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.description_outlined, size: 18),
              SizedBox(width: 6),
              Text('Deskripsi Produk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 10),
          Text(p.deskripsi.isEmpty ? 'Tidak ada deskripsi.' : p.deskripsi,
              style: TextStyle(color: Colors.grey[700], height: 1.6, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _storeCard(Product p) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF03AC0E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.storefront, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(p.toko.nama, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.verified, size: 15, color: Colors.black),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  p.toko.alamat != null && p.toko.alamat!.isNotEmpty ? p.toko.alamat! : 'Polewali Mandar',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _bottomBar(Product p) {
    final app = context.watch<AppState>();
    final isFav = app.favoritIds.contains(p.id);
    final enabled = p.stok > 0 && !_actionLoading;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(isFav ? Icons.favorite : Icons.favorite_border,
                    color: isFav ? Colors.red : Colors.black87, size: 22),
                onPressed: enabled ? _toggleFavorit : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                onPressed: enabled ? _buyNow : null,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Beli', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: enabled ? _addToCart : null,
                icon: _actionLoading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.add_shopping_cart, size: 20),
                label: Text(
                  p.stok <= 0 ? 'Stok Habis' : (_actionLoading ? 'Memuat...' : 'Tambah ke Keranjang'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF03AC0E),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _feature(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
          child: Icon(icon, size: 14, color: const Color(0xFF03AC0E)),
        ),
        const SizedBox(width: 5),
        Flexible(child: Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w500))),
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
          Text('$_qty', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          IconButton(
            icon: const Icon(Icons.add, size: 16),
            onPressed: _qty < (_product?.stok ?? 1) ? () => setState(() => _qty++) : null,
          ),
        ],
      ),
    );
  }
}

class _GallerySection extends StatefulWidget {
  final Product product;
  const _GallerySection({required this.product});

  @override
  State<_GallerySection> createState() => _GallerySectionState();
}

class _GallerySectionState extends State<_GallerySection> {
  final PageController _controller = PageController();
  int _current = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imgs = widget.product.gambarUrl;
    final hasImages = imgs.isNotEmpty;
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          height: 300,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (!hasImages)
                Container(color: Colors.grey[100], child: const Icon(Icons.image, size: 64, color: Colors.grey))
              else
                RepaintBoundary(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: imgs.length,
                    allowImplicitScrolling: true,
                    onPageChanged: (i) => setState(() => _current = i),
                    itemBuilder: (_, i) => _networkImage(i, imgs[i]),
                  ),
                ),
              if (widget.product.hasDiskon)
                Positioned(
                  top: 12,
                  left: 12,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: 1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('-${widget.product.diskonPersen}%',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (hasImages && imgs.length > 1)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(imgs.length, (i) {
                final active = i == _current;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active ? const Color(0xFF03AC0E) : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _networkImage(int index, String url) {
    final img = CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 250),
      placeholder: (_, _) => Container(color: Colors.grey[100], child: const Icon(Icons.image, size: 40, color: Colors.grey)),
      errorWidget: (_, _, _) => Container(color: Colors.grey[100], child: const Icon(Icons.image, size: 40, color: Colors.grey)),
    );
    if (index == 0) {
      return Hero(tag: 'product-image-${widget.product.id}', child: img);
    }
    return img;
  }
}

class _DetailSkeleton extends StatefulWidget {
  const _DetailSkeleton({super.key});

  @override
  State<_DetailSkeleton> createState() => _DetailSkeletonState();
}

class _DetailSkeletonState extends State<_DetailSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget box(double w, double h, {double radius = 8}) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        return Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              colors: const [Color(0xFFE6E6E6), Color(0xFFF8F8F8), Color(0xFFE6E6E6)],
              stops: const [0.1, 0.5, 0.9],
              begin: Alignment(-1.2 + 2.4 * t, 0),
              end: Alignment(0.2 + 2.4 * t, 0),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('skeleton'),
      backgroundColor: Colors.grey[50],
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: const [Color(0xFFE6E6E6), Color(0xFFF8F8F8), Color(0xFFE6E6E6)],
                  stops: const [0.1, 0.5, 0.9],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  box(120, 10),
                  const SizedBox(height: 10),
                  box(double.infinity, 18, radius: 6),
                  const SizedBox(height: 6),
                  box(200, 18, radius: 6),
                  const SizedBox(height: 16),
                  box(150, 26),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      box(90, 12),
                      const SizedBox(width: 10),
                      box(70, 12),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: box(double.infinity, 36, radius: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
