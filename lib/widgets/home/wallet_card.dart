import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';

/// Kartu saldo dompet — versi terang, minimal, sesuai arah desain modern.
class WalletCard extends StatelessWidget {
  final String label;
  final String amount;
  final VoidCallback? onTap;
  const WalletCard({super.key, required this.label, required this.amount, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: AppColors.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(color: AppColors.neutral100, shape: BoxShape.circle),
                child: const Icon(Icons.account_balance_wallet_outlined, size: 20, color: AppColors.neutral900),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontSize: 12, color: AppColors.neutral600)),
                    const SizedBox(height: 2),
                    Text(amount,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.neutral900)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 20, color: AppColors.neutral300),
            ],
          ),
        ),
      ),
    );
  }
}
