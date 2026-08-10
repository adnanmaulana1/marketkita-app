import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../models/product.dart';
import '../../services/api.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../product_card.dart';

/// Rekomendasi "Produk Serupa": produk satu kategori (kecuali produk ini).
/// Pakai API produk yang sudah ada, tanpa perubahan backend.
class RelatedProducts extends StatefulWidget {
  final int currentId;
  final String kategoriSlug;
  const RelatedProducts({super.key, required this.currentId, required this.kategoriSlug});

  @override
  State<RelatedProducts> createState() => _RelatedProductsState();
}

class _RelatedProductsState extends State<RelatedProducts> {
  List<Product>? _items;
  bool _loading = true;
  bool _errored = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errored = false;
    });
    try {
      final res = await Api.products(kategori: widget.kategoriSlug, page: 1, perPage: 10);
      if (!mounted) return;
      setState(() {
        _items = res.products.where((p) => p.id != widget.currentId).take(8).toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errored = true;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _skeleton();
    if (_errored || _items == null || _items!.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            'Produk Serupa',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.neutral900),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: ProductCard.cardHeight,
            ),
            itemCount: _items!.length,
            itemBuilder: (_, i) => ProductCard(product: _items![i]),
          ),
        ),
      ],
    );
  }

  Widget _skeleton() {
    return Shimmer.fromColors(
      baseColor: AppColors.neutral200,
      highlightColor: AppColors.neutral100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Container(height: 18, width: 140, decoration: BoxDecoration(color: AppColors.neutral200, borderRadius: BorderRadius.circular(AppRadius.md))),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Expanded(child: Container(height: 240, decoration: BoxDecoration(color: AppColors.neutral200, borderRadius: BorderRadius.circular(AppRadius.xl)))),
                const SizedBox(width: 12),
                Expanded(child: Container(height: 240, decoration: BoxDecoration(color: AppColors.neutral200, borderRadius: BorderRadius.circular(AppRadius.xl)))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
