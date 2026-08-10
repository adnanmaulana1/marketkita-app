import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config.dart';
import '../../models/banner.dart';
import '../../models/product.dart';
import '../../services/api.dart';
import '../../state/app_state.dart';
import '../../utils/format.dart';
import '../../widgets/product_card.dart';
import '../cart_screen.dart';
import '../chat_list_screen.dart';
import '../orders_screen.dart';
import '../profile_screen.dart';
import 'product_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  List<Category> _cats = [];
  List<Product> _products = [];
  List<Product> _flashProducts = [];
  int _page = 1;
  int _pages = 1;
  String _q = '';
  String _cat = '';
  final String _sort = '';
  bool _loading = true;
  bool _loadingMore = false;
  final _scroll = ScrollController();
  int _bannerIndex = 0;
  final _bannerController = PageController();
  Timer? _bannerTimer;

  static const _fallbackBanners = [
    (title: 'Gratis Ongkir', subtitle: 'Kirim ke seluruh Polewali & sekitarnya', icon: Icons.local_shipping_outlined),
    (title: 'Flash Sale', subtitle: 'Hemat sampai 50% produk pilihan', icon: Icons.flash_on_outlined),
    (title: 'Top Up Dompet', subtitle: 'Isi saldo MarketKita, bayar lebih mudah', icon: Icons.account_balance_wallet_outlined),
  ];

  List<BannerItem> _banners = [];

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300 && !_loadingMore && _page < _pages) {
        _loadMore();
      }
    });
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_bannerController.hasClients && _bannerCount > 0) {
        final next = (_bannerIndex + 1) % _bannerCount;
        _bannerController.animateToPage(next, duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
      }
    });
    _load();
    _loadFlashProducts();
  }

  int get _bannerCount => _banners.isNotEmpty ? _banners.length : _fallbackBanners.length;

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final app = context.read<AppState>();
      if (_cats.isEmpty) {
        _cats = await Api.categories();
      }
      final banners = await Api.banners();
      final res = await Api.products(kategori: _cat, q: _q, sort: _sort, page: 1);
      setState(() {
        _banners = banners.where((b) => AppConfig.resolveUrl(b.gambarUrl).isNotEmpty).toList();
        _products = res.products;
        _pages = res.pages;
        _page = 1;
      });
      app.refreshCart();
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadFlashProducts() async {
    try {
      final res = await Api.products(kategori: '', q: '', sort: _sort, page: 1);
      if (!mounted) return;
      setState(() {
        _flashProducts = res.products.where((p) => p.hasDiskon).take(8).toList();
      });
    } catch (_) {}
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      final res = await Api.products(kategori: _cat, q: _q, sort: _sort, page: _page + 1);
      setState(() {
        _products.addAll(res.products);
        _page++;
        _pages = res.pages;
      });
    } catch (_) {}
    setState(() => _loadingMore = false);
  }

  void _showError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
  }

  void _search(String q) {
    _q = q;
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _tab == 0 ? _homeAppBar() : null,
      body: IndexedStack(
        index: _tab,
        children: [
          _homeBody(),
          const CartScreen(),
          const OrdersScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        backgroundColor: Colors.white,
        indicatorColor: Colors.black.withValues(alpha: 0.08),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Beranda'),
          NavigationDestination(icon: Icon(Icons.shopping_cart_outlined), selectedIcon: Icon(Icons.shopping_cart), label: 'Keranjang'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Pesanan'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  PreferredSizeWidget _homeAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Icon(Icons.location_on_outlined, size: 18, color: Colors.black87),
            const SizedBox(width: 4),
            const Text('Kirim ke Polewali',
                style: TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w600)),
            const Icon(Icons.keyboard_arrow_down, size: 20, color: Colors.grey),
          ],
        ),
      ),
      actions: [
        // Isolasi: hanya badge chat yang rebuild saat unread berubah.
        Consumer<AppState>(
          builder: (_, app, _) {
            final chatUnread = app.chatUnread;
            return IconButton(
              icon: Badge(
                isLabelVisible: chatUnread > 0,
                backgroundColor: Colors.black,
                label: Text('$chatUnread'),
                child: const Icon(Icons.chat_bubble_outline, color: Colors.black87),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatListScreen()),
              ),
            );
          },
        ),
        // Isolasi: hanya badge keranjang yang rebuild saat count berubah.
        Consumer<AppState>(
          builder: (_, app, _) {
            final cartCount = app.cart?.count ?? 0;
            return IconButton(
              icon: Badge(
                isLabelVisible: cartCount > 0,
                backgroundColor: Colors.black,
                label: Text('$cartCount'),
                child: const Icon(Icons.shopping_cart_outlined, color: Colors.black87),
              ),
              onPressed: () => setState(() => _tab = 1),
            );
          },
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _searchRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onSubmitted: _search,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Cari di MarketKita',
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                prefixIcon: Icon(Icons.search, color: Colors.grey[600], size: 22),
                suffixIcon: _q.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _q = '';
                          _load();
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _walletBar() {
    // Isolasi: hanya kartu saldo yang rebuild saat saldo/nama berubah,
    // bukan seluruh home body.
    return Selector<AppState, (int, String)>(
      selector: (_, app) => (app.user?.saldo ?? 0, app.user?.nama ?? ''),
      builder: (_, data, _) {
        final (saldo, name) = data;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Saldo Dompet', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                    const SizedBox(height: 2),
                    Text(rupiah(saldo), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              if (name.isNotEmpty)
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified, color: Colors.black, size: 14),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _homeBody() {
    if (_loading && _products.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _searchRow(),
          _walletBar(),
          const SizedBox(height: 4),
          RepaintBoundary(child: _bannerCarousel()),
          RepaintBoundary(child: _bannerDots()),
          RepaintBoundary(child: _flashSale()),
          RepaintBoundary(child: _categorySection()),
          RepaintBoundary(child: _productSectionHeader()),
          RepaintBoundary(child: _feedPills()),
          RepaintBoundary(child: _productGrid()),
          if (_loadingMore) const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }

  Widget _bannerCarousel() {
    final server = _banners;
    final count = _bannerCount;
    return SizedBox(
      height: 150,
      child: PageView.builder(
        controller: _bannerController,
        itemCount: count,
        onPageChanged: (i) => setState(() => _bannerIndex = i),
        itemBuilder: (_, i) {
          if (server.isNotEmpty) {
            final b = server[i];
            return _serverBannerCard(b);
          }
          final f = _fallbackBanners[i];
          return InkWell(
            onTap: i == 2 ? () => setState(() => _tab = 3) : null,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: i.isEven
                      ? const [Color(0xFF171717), Color(0xFF3A3A3A)]
                      : const [Color(0xFF2B2B2B), Color(0xFF555555)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(f.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          Text(f.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ),
                    Icon(f.icon, color: Colors.white24, size: 72),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _serverBannerCard(BannerItem b) {
    final url = AppConfig.resolveUrl(b.gambarUrl);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            memCacheWidth: 800,
            placeholder: (_, _) => Container(color: Colors.grey.shade200, child: const Icon(Icons.image, color: Colors.grey, size: 36)),
            errorWidget: (_, _, _) => Container(
              color: Colors.grey.shade200,
              child: const Icon(Icons.image, color: Colors.grey, size: 36),
            ),
          ),
          if (b.judul.isNotEmpty || b.subtitle.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withValues(alpha: 0.05), Colors.black.withValues(alpha: 0.65)],
                ),
              ),
            ),
          if (b.judul.isNotEmpty || b.subtitle.isNotEmpty)
            Positioned(
              left: 14,
              right: 14,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (b.badge.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(6)),
                      child: Text(b.badge.split(' ').skip(1).join(' '),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                    ),
                  const SizedBox(height: 6),
                  Text(b.judul, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, height: 1.2)),
                  if (b.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(b.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11)),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _bannerDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_bannerCount, (i) {
        final active = i == _bannerIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
          width: active ? 16 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? Colors.black : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  Widget _categorySection() {
    if (_cats.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Text('Kategori', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 5,
            mainAxisSpacing: 12,
            crossAxisSpacing: 4,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              _catTile('Semua', Icons.apps, ''),
              for (final c in _cats) _catTile(c.nama, _categoryIcon(c.nama), c.slug),
            ],
          ),
        ),
      ],
    );
  }

  Widget _catTile(String label, IconData icon, String slug) {
    final active = _cat == slug;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        setState(() => _cat = active ? '' : slug);
        _load();
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: active ? Colors.black : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(14),
              border: active ? null : Border.all(color: Colors.grey.shade200),
            ),
            child: Icon(icon, color: active ? Colors.white : Colors.black, size: 22),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, fontWeight: active ? FontWeight.w700 : FontWeight.w400)),
          ),
        ],
      ),
    );
  }

  Widget _flashSale() {
    final items = _flashProducts;
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Row(
            children: [
              const Icon(Icons.flash_on, color: Colors.black, size: 18),
              const SizedBox(width: 4),
              const Text('KEJAR DISKON',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, letterSpacing: 0.5)),
              const Spacer(),
              Text('Lihat Semua', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w700)),
              const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF171717), Color(0xFF3A3A3A)],
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _FlashCountdown(),
              const SizedBox(height: 10),
              SizedBox(
                height: 205,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (_, i) => _flashCard(items[i]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _flashCard(Product p) {
    final progress = p.stok > 0 ? (p.stok / (p.stok + 20)).clamp(0.0, 1.0) : 0.0;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: p.id, initialProduct: p)),
      ),
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 92,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: Colors.grey[100],
                    child: p.gambarUrl.isEmpty
                        ? const Icon(Icons.image, color: Colors.grey, size: 34)
                        : CachedNetworkImage(
                            imageUrl: p.gambarUrl.first,
                            fit: BoxFit.cover,
                            memCacheWidth: 240,
                            placeholder: (_, _) => const Icon(Icons.image, color: Colors.grey, size: 34),
                            errorWidget: (_, _, _) => const Icon(Icons.image, color: Colors.grey, size: 34),
                          ),
                  ),
                  if (p.hasDiskon)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(4)),
                        child: Text('-${p.diskonPersen}%',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 28,
                    child: Text(p.nama, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, height: 1.25)),
                  ),
                  const SizedBox(height: 4),
                  Text(rupiah(p.harga), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                  Text(rupiah(p.hargaCoret ?? p.harga),
                      style: TextStyle(fontSize: 9, color: Colors.grey[400], decoration: TextDecoration.lineThrough)),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation(Colors.black),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Center(
                    child: Text('Segera Habis', style: TextStyle(fontSize: 9, color: Colors.grey[600], fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _productSectionHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Row(
        children: [
          const Text('Semua Produk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const Spacer(),
          Text('${_products.length} produk', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _feedPills() {
    final pills = <({String label, String slug})>[
      (label: 'For You', slug: ''),
      for (final c in _cats.take(4)) (label: c.nama, slug: c.slug),
    ];
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: pills.map((p) {
          final active = _cat == p.slug;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() => _cat = active ? '' : p.slug);
                _load();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: active ? Colors.black : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(p.label,
                    style: TextStyle(
                        fontSize: 12,
                        color: active ? Colors.white : Colors.black87,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _productGrid() {
    if (_products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            const Text('Produk tidak ditemukan', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardW = (constraints.maxWidth - 12) / 2;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final p in _products) SizedBox(width: cardW, child: ProductCard(product: p)),
            ],
          );
        },
      ),
    );
  }

  IconData _categoryIcon(String nama) {
    final n = nama.toLowerCase();
    if (n.contains('pakaian') || n.contains('fashion') || n.contains('baju') || n.contains('sepatu')) return Icons.checkroom;
    if (n.contains('elektronik') || n.contains('gadget') || n.contains('handphone') || n.contains('hp')) return Icons.phone_android;
    if (n.contains('makanan') || n.contains('minuman') || n.contains('sembako') || n.contains('pangan')) return Icons.local_grocery_store_outlined;
    if (n.contains('rumah') || n.contains('perabot') || n.contains('peralatan')) return Icons.chair_outlined;
    if (n.contains('kecantikan') || n.contains('kosmetik') || n.contains('perawatan')) return Icons.spa_outlined;
    if (n.contains('olahraga') || n.contains('fitness')) return Icons.sports_soccer;
    if (n.contains('otomotif') || n.contains('kendaraan')) return Icons.directions_car_outlined;
    if (n.contains('jasa') || n.contains('service') || n.contains('perbaikan')) return Icons.handyman_outlined;
    if (n.contains('buku') || n.contains('tulis')) return Icons.menu_book_outlined;
    return Icons.category_outlined;
  }
}

class _FlashCountdown extends StatefulWidget {
  const _FlashCountdown();

  @override
  State<_FlashCountdown> createState() => _FlashCountdownState();
}

class _FlashCountdownState extends State<_FlashCountdown> {
  Timer? _timer;

  Duration _remaining() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final d = midnight.difference(now);
    return d.isNegative ? Duration.zero : d;
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _box(String txt) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(6)),
      child: Text(txt, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = _remaining();
    final h = r.inHours.toString().padLeft(2, '0');
    final m = r.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = r.inSeconds.remainder(60).toString().padLeft(2, '0');
    return Row(
      children: [
        const Icon(Icons.timer_outlined, color: Colors.white70, size: 16),
        const SizedBox(width: 6),
        Text('Berakhir dalam', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
        const SizedBox(width: 8),
        _box(h),
        const Text(':', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        _box(m),
        const Text(':', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        _box(s),
      ],
    );
  }
}
