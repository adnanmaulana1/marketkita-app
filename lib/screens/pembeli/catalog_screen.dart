import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../services/api.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text.dart';
import '../../widgets/product_card.dart';
import '../../widgets/shimmer_box.dart';

/// Halaman katalog per kategori — pola listing page Tokopedia.
class CatalogScreen extends StatefulWidget {
  final String categorySlug;
  final String title;
  const CatalogScreen({super.key, required this.categorySlug, required this.title});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  static const _sortOptions = [
    (label: 'Relevansi', value: ''),
    (label: 'Terlaris', value: 'terlaris'),
    (label: 'Termurah', value: 'termurah'),
    (label: 'Termahal', value: 'termahal'),
    (label: 'Rating', value: 'rating'),
  ];

  List<Product> _products = [];
  int _page = 1;
  int _pages = 1;
  int _total = 0;
  String _sort = '';
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
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

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await Api.products(kategori: widget.categorySlug, sort: _sort, page: 1);
      setState(() {
        _products = res.products;
        _pages = res.pages;
        _total = res.total;
        _page = 1;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      final res = await Api.products(kategori: widget.categorySlug, sort: _sort, page: _page + 1);
      setState(() {
        _products.addAll(res.products);
        _page++;
        _pages = res.pages;
        _total = res.total;
      });
    } catch (_) {}
    setState(() => _loadingMore = false);
  }

  void _changeSort(String value) {
    if (value == _sort) return;
    _sort = value;
    _load();
  }

  void _resetSort() {
    _sort = '';
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        title: Text(widget.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.neutral900)),
      ),
      body: _body(),
    );
  }

  Widget _body() {
    if (_loading && _products.isEmpty) {
      return _loadingSkeleton();
    }
    if (_error != null && _products.isEmpty) {
      return _errorState();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sortChips(),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 8, AppSpacing.lg, 4),
          child: Text('$_total produk', style: AppText.caption),
        ),
        Expanded(child: _grid()),
      ],
    );
  }

  Widget _sortChips() {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 6, AppSpacing.lg, 0),
        children: _sortOptions.map((o) {
          final active = _sort == o.value;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => _changeSort(o.value),
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : AppColors.white,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: active ? null : Border.all(color: AppColors.neutral300),
                ),
                child: Text(o.label,
                    style: TextStyle(
                        fontSize: 12,
                        color: active ? AppColors.white : AppColors.neutral900,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _grid() {
    if (_products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off, size: 48, color: AppColors.neutral400),
              const SizedBox(height: 12),
              const Text('Produk tidak ditemukan', style: AppText.title),
              const SizedBox(height: 4),
              Text('Coba kategori atau urutan lain, ya.', textAlign: TextAlign.center, style: AppText.caption),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _resetSort,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                ),
                child: const Text('Muat Ulang'),
              ),
            ],
          ),
        ),
      );
    }
    return GridView.builder(
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 4, AppSpacing.lg, 24),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: ProductCard.cardHeight,
      ),
      itemCount: _products.length + (_loadingMore ? 2 : 0),
      itemBuilder: (_, i) {
        if (i >= _products.length) {
          return const ShimmerBox(height: 290, radius: AppRadius.xl);
        }
        return ProductCard(product: _products[i]);
      },
    );
  }

  Widget _loadingSkeleton() {
    return GridView.count(
      padding: const EdgeInsets.all(AppSpacing.lg),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.62,
      children: List.generate(6, (_) => const ShimmerBox(height: 280, radius: AppRadius.xl)),
    );
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 56, color: AppColors.neutral400),
            const SizedBox(height: 16),
            const Text('Koneksi terputus', style: AppText.title),
            const SizedBox(height: 8),
            Text(
              'Periksa jaringan kamu dan coba lagi, ya.',
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(color: AppColors.neutral600),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Coba Lagi'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
