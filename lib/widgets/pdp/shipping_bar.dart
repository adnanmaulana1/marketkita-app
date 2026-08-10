import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/home/alamat_sheet.dart';

/// Bar "Kirim ke ..." di PDP. Memakai alamat aktif dari AppState.
/// Tap untuk membuka sheet pemilihan alamat.
class ShippingBar extends StatelessWidget {
  const ShippingBar({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final alamat = app.alamatAktif?.alamat;
    return Material(
      color: AppColors.neutral100,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () => showAlamatSheet(context),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Icons.local_shipping_outlined, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kirim ke',
                      style: TextStyle(fontSize: 11, color: AppColors.neutral600, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      alamat ?? 'Pilih alamat pengiriman',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: AppColors.neutral900, fontWeight: FontWeight.w700, height: 1.3),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Gratis ongkir area Polewali',
                      style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(Icons.chevron_right, size: 20, color: AppColors.neutral400),
            ],
          ),
        ),
      ),
    );
  }
}
