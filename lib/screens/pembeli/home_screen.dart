import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../services/api.dart';
import '../../state/app_state.dart';
import '../../utils/format.dart';
import '../../widgets/product_card.dart';
import '../cart_screen.dart';
import '../chat_list_screen.dart';
import '../orders_screen.dart';
import '../profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  List<Category> _cats = [];
  List<Product> _products = [];
  int _page = 1;
  int _pages = 1;
  String _q = '';
  String _cat = '';
  String _sort = '';
  bool _loading = true;
  bool _loadingMore = false;
  final _scroll = ScrollController();
  int _bannerIndex = 0;
  final _bannerController = PageController();
  Timer? _bannerTimer;

  static const _sortOptions = [
    ('', 'Terbaru'),
    ('ulasan', 'Terlaris'),
    ('termurah', 'Harga Termurah'),
    ('termahal', 'Harga Termahal'),
  ];

  static const _banners = [
    (title: 'Gratis Ongkir', subtitle: 'Kirim ke seluruh Polewali & sekitarnya', icon: Icons.local_shipping_outlined),
    (title: 'Flash Sale', subtitle: 'Hemat sampai 50% produk pilihan', icon: Icons.flash_on_outlined),
    (title: 'Top Up Dompet', subtitle: 'Isi saldo MarketKita, bayar lebih mudah', icon: Icons.account_balance_wallet_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300 && !_loadingMore && _page < _pages) {
        _loadMore();
      }
    });
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_bannerController.hasClients) {
        final next = (_bannerIndex + 1) % _banners.length;
        _bannerController.animateToPage(next, duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
      }
    });
    _load();
  }

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
      final res = await Api.products(kategori: _cat, q: _q, sort: _sort, page: 1);
      setState(() {
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
    final app = context.watch<AppState>();

    return Scaffold(
      appBar: _tab == 0 ? _homeAppBar(app) : null,
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

  PreferredSizeWidget _homeAppBar(AppState app) {
    final cartCount = app.cart?.count ?? 0;
    final chatUnread = app.chatUnread;
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      toolbarHeight: 96,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 8, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: Colors.black87),
                const SizedBox(width: 4),
                const Text('Kirim ke Polewali',
                    style: TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w600)),
                const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey),
                const Spacer(),
                IconButton(
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
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: Badge(
                    isLabelVisible: cartCount > 0,
                    backgroundColor: Colors.black,
                    label: Text('$cartCount'),
                    child: const Icon(Icons.shopping_cart_outlined, color: Colors.black87),
                  ),
                  onPressed: () => setState(() => _tab = 1),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextField(
                      onSubmitted: _search,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Cari di MarketKita',
                        hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
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
                ),
                const SizedBox(width: 8),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.tune, color: Colors.white, size: 20),
                    onPressed: _openSortSheet,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Urutkan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ),
            ..._sortOptions.map((s) {
              final active = _sort == s.$1;
              return ListTile(
                leading: Icon(active ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: active ? Colors.black : Colors.grey),
                title: Text(s.$2, style: TextStyle(fontWeight: active ? FontWeight.w700 : FontWeight.w400)),
                onTap: () {
                  _sort = s.$1;
                  Navigator.pop(ctx);
                  _load();
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
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
          const SizedBox(height: 8),
          _bannerCarousel(),
          _bannerDots(),
          _categorySection(),
          _promoStrip(),
          _productSectionHeader(),
          _sortRow(),
          _productGrid(),
          if (_loadingMore) const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }

  Widget _bannerCarousel() {
    return SizedBox(
      height: 150,
      child: PageView.builder(
        controller: _bannerController,
        itemCount: _banners.length,
        onPageChanged: (i) => setState(() => _bannerIndex = i),
        itemBuilder: (_, i) {
          final b = _banners[i];
          return Container(
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
                        Text(b.title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Text(b.subtitle, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                  Icon(b.icon, color: Colors.white24, size: 72),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _bannerDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_banners.length, (i) {
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
        SizedBox(
          height: 96,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _cats.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 18),
            itemBuilder: (_, i) {
              if (i == 0) return _catTile('Semua', Icons.apps, '');
              final c = _cats[i - 1];
              return _catTile(c.nama, _categoryIcon(c.nama), c.slug);
            },
          ),
        ),
      ],
    );
  }

  Widget _catTile(String label, IconData icon, String slug) {
    final active = _cat == slug;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        setState(() => _cat = active ? '' : slug);
        _load();
      },
      child: SizedBox(
        width: 56,
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: active ? Colors.black : Colors.grey.shade100,
                shape: BoxShape.circle,
                border: active ? null : Border.all(color: Colors.grey.shade200),
              ),
              child: Icon(icon, color: active ? Colors.white : Colors.black, size: 24),
            ),
            const SizedBox(height: 6),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, fontWeight: active ? FontWeight.w700 : FontWeight.w400)),
          ],
        ),
      ),
    );
  }

  Widget _promoStrip() {
    final items = _products.where((p) => p.hasDiskon).take(8).toList();
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(6)),
                child: const Text('HEMAT', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 8),
              const Text('Promo & Penawaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _promoCard(items[i]),
          ),
        ),
      ],
    );
  }

  Widget _promoCard(Product p) {
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                  clipBehavior: Clip.antiAlias,
                  child: p.gambarUrl.isEmpty
                      ? const Icon(Icons.image, color: Colors.grey, size: 40)
                      : Image.network(p.gambarUrl.first, fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(Icons.image, color: Colors.grey, size: 40)),
                ),
                if (p.hasDiskon)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(4)),
                      child: Text('-${p.diskonPersen}%',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(p.nama, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(rupiah(p.harga), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
        ],
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

  Widget _sortRow() {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: _sortOptions.map((s) {
          final active = _sort == s.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(s.$2,
                  style: TextStyle(
                      fontSize: 12,
                      color: active ? Colors.white : Colors.black87,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
              selected: active,
              selectedColor: Colors.black,
              backgroundColor: Colors.white,
              side: BorderSide(color: active ? Colors.black : Colors.grey.shade300),
              showCheckmark: false,
              onSelected: (_) {
                _sort = s.$1;
                _load();
              },
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
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _products.length,
      itemBuilder: (_, i) => ProductCard(product: _products[i]),
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
