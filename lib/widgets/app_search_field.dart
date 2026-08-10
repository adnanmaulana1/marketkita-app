import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

class AppSearchField extends StatelessWidget {
  final String hint;
  final bool showClear;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;
  const AppSearchField({
    super.key,
    this.hint = 'Cari kebutuhanmu di MarketKita...',
    this.showClear = false,
    required this.onSubmitted,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.neutral400, fontSize: 14),
        filled: true,
        fillColor: AppColors.neutral100,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        prefixIcon: const Icon(Icons.search, color: AppColors.neutral600, size: 22),
        suffixIcon: showClear
            ? IconButton(
                icon: const Icon(Icons.close, size: 18, color: AppColors.neutral600),
                onPressed: onClear,
              )
            : null,
      ),
    );
  }
}
