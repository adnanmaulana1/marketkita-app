import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../services/api.dart';
import '../../state/app_state.dart';
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

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300 && !_loadingMore && _page < _pages) {
        _loadMore();
      }
    });
    _load();
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
    final cartCount = app.cart?.count ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF171717),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.storefront, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            const Text('MarketKita', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: app.chatUnread > 0,
              label: Text('${app.chatUnread}'),
              child: const Icon(Icons.chat_bubble_outline),
            ),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListScreen())),
          ),
          IconButton(
            icon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              onSubmitted: _search,
              decoration: InputDecoration(
                hintText: 'Cari produk, merek, atau kategori...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _q.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _q = '';
                          _load();
                        },
                      ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide(color: Colors.grey.shade300)),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      controller: _scroll,
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        _categoryRow(),
                        _sortRow(),
                        _productGrid(),
                        if (_loadingMore) const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: _onTabSelected,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Beranda'),
          NavigationDestination(icon: Icon(Icons.shopping_cart_outlined), selectedIcon: Icon(Icons.shopping_cart), label: 'Keranjang'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Pesanan'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  Future<void> _onTabSelected(int i) async {
    setState(() => _tab = i);
    switch (i) {
      case 1:
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
      case 2:
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen()));
      case 3:
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
      default:
        return;
    }
    if (mounted) setState(() => _tab = 0);
  }

  Widget _categoryRow() {
    if (_cats.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 64,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        scrollDirection: Axis.horizontal,
        itemCount: _cats.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          if (i == 0) {
            return _chip('Semua', '', Icons.apps);
          }
          final c = _cats[i - 1];
          return _chip(c.nama, c.slug, Icons.category_outlined);
        },
      ),
    );
  }

  Widget _chip(String label, String slug, IconData icon) {
    final active = _cat == slug;
    return ChoiceChip(
      label: Text(label),
      selected: active,
      onSelected: (_) {
        _cat = active ? '' : slug;
        _load();
      },
      showCheckmark: false,
    );
  }

  Widget _sortRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Text('Urutkan:', style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<String>(
              value: _sort.isEmpty ? null : _sort,
              isExpanded: true,
              hint: const Text('Terbaru', style: TextStyle(fontSize: 13)),
              items: const [
                DropdownMenuItem(value: '', child: Text('Terbaru')),
                DropdownMenuItem(value: 'termurah', child: Text('Harga Termurah')),
                DropdownMenuItem(value: 'termahal', child: Text('Harga Termahal')),
                DropdownMenuItem(value: 'ulasan', child: Text('Terlaris')),
              ],
              onChanged: (v) {
                _sort = v ?? '';
                _load();
              },
            ),
          ),
        ],
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
}
