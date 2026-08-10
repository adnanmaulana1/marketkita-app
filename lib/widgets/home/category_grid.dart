import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

class CategoryTileData {
  final String label;
  final IconData icon;
  final String slug;
  const CategoryTileData({required this.label, required this.icon, required this.slug});
}

/// Grid kategori — ikon lingkaran 4 kolom, plus bottom sheet semua kategori.
class CategoryGrid extends StatelessWidget {
  final String title;
  final List<CategoryTileData> items;
  final String selectedSlug;
  final ValueChanged<String> onSelect;
  final VoidCallback? onShowAll;
  const CategoryGrid({
    super.key,
    required this.title,
    required this.items,
    required this.selectedSlug,
    required this.onSelect,
    this.onShowAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 24, AppSpacing.lg, 12),
          child: Row(
            children: [
              const Text('Kategori',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.neutral900)),
              const Spacer(),
              if (onShowAll != null)
                InkWell(
                  onTap: onShowAll,
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Lihat Semua',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.neutral600)),
                        SizedBox(width: 2),
                        Icon(Icons.chevron_right, size: 16, color: AppColors.neutral600),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              boxShadow: AppColors.cardShadow,
            ),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 4,
              children: [for (final d in items) _tile(d)],
            ),
          ),
        ),
      ],
    );
  }

  Widget _tile(CategoryTileData d) {
    final active = d.slug == selectedSlug;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.full),
      onTap: () => onSelect(d.slug),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: active ? AppColors.primary : AppColors.neutral100,
              shape: BoxShape.circle,
              border: active ? null : Border.all(color: AppColors.neutral200),
            ),
            child: Icon(d.icon, size: 22, color: active ? AppColors.white : AppColors.neutral900),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(d.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: AppColors.neutral900)),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet daftar semua kategori — pola Tokopedia "Lihat Semua Kategori".
void showAllCategories(BuildContext context, List<CategoryTileData> items, ValueChanged<String> onSelect) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(color: AppColors.neutral300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Semua Kategori',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.neutral900)),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              mainAxisSpacing: 16,
              crossAxisSpacing: 4,
              children: items.map((d) {
                return InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  onTap: () {
                    Navigator.pop(context);
                    onSelect(d.slug);
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.neutral100,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.neutral200),
                        ),
                        child: Icon(d.icon, size: 22, color: AppColors.neutral900),
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(d.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.neutral900)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    ),
  );
}
