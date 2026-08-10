import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../config.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../utils/format.dart';

/// Section "Kejar Diskon" — tanpa gradient gelap, kartu putih ber-shadow.
class FlashSaleSection extends StatelessWidget {
  final List<Product> items;
  final ValueListenable<Duration> remaining;
  final ValueChanged<Product> onTapProduct;
  const FlashSaleSection({
    super.key,
    required this.items,
    required this.remaining,
    required this.onTapProduct,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 24, AppSpacing.lg, 12),
          child: Row(
            children: [
              const Icon(Icons.flash_on, size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              const Text('Kejar Diskon',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.neutral900)),
              const Spacer(),
              ValueListenableBuilder<Duration>(
                valueListenable: remaining,
                builder: (_, d, _) => _timerPill(d),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 264,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _card(items[i]),
          ),
        ),
      ],
    );
  }

  Widget _timerPill(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, size: 12, color: Colors.white70),
          const SizedBox(width: 4),
          Text('$h:$m:$s',
              style: const TextStyle(color: AppColors.white, fontSize: 11, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _card(Product p) {
    final progress = p.stok > 0 ? (p.stok / (p.stok + 20)).clamp(0.0, 1.0) : 0.0;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      onTap: () => onTapProduct(p),
      child: Container(
        width: 132,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: AppColors.cardShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 132,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: AppColors.neutral100,
                    child: p.gambarUrl.isEmpty
                        ? const Icon(Icons.image, color: AppColors.neutral400, size: 34)
                        : Image.network(AppConfig.resolveImageUrl(p.gambarUrl.first),
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(Icons.image, color: AppColors.neutral400, size: 34)),
                  ),
                  if (p.hasDiskon)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Text('-${p.diskonPersen}%',
                            style: const TextStyle(color: AppColors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.nama,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.3)),
                  const SizedBox(height: 4),
                  Text(rupiah(p.harga), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                  if (p.hasDiskon) ...[
                    const SizedBox(height: 1),
                    Text(rupiah(p.hargaCoret ?? p.harga),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10, color: AppColors.neutral400, decoration: TextDecoration.lineThrough)),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 4,
                            backgroundColor: AppColors.neutral200,
                            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('Sisa ${p.stok}',
                          style: const TextStyle(fontSize: 10, color: AppColors.neutral600, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.flash_on, size: 11, color: AppColors.primary),
                      const SizedBox(width: 3),
                      Text('${p.terjual} terjual', style: const TextStyle(fontSize: 10, color: AppColors.neutral600)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
