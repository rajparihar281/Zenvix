import 'package:flutter/material.dart';
import 'package:zenvix/core/theme/app_colors.dart';
import 'package:zenvix/core/theme/app_theme.dart';

class PdfLoadingWidget extends StatelessWidget {
  const PdfLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.background,
    child: const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.electricPurple),
          SizedBox(height: AppTheme.spacingMD),
          Text(
            'Loading PDF...',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    ),
  );
}
