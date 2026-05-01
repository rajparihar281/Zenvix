import 'package:flutter/material.dart';
import 'package:zenvix/core/theme/app_colors.dart';
import 'package:zenvix/core/theme/app_theme.dart';
import 'package:zenvix/features/qr_tools/presentation/screens/qr_generator_screen.dart';
import 'package:zenvix/features/qr_tools/presentation/screens/qr_scanner_screen.dart';

class QrToolsScreen extends StatelessWidget {
  const QrToolsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      title: const Text('QR Tools'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
    ),
    body: Padding(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      child: Column(
        children: [
          const SizedBox(height: AppTheme.spacingLG),
          // Hero icon
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.warning.withValues(alpha: 0.2),
                  AppColors.accentCyan.withValues(alpha: 0.1),
                ],
              ),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.4),
              ),
            ),
            child: const Icon(
              Icons.qr_code_2_rounded,
              size: 44,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMD),
          Text('QR Tools', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppTheme.spacingXS),
          Text(
            'Scan or generate QR codes instantly',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingXXL),

          // Tool cards
          _ToolCard(
            icon: Icons.qr_code_scanner_rounded,
            title: 'QR Scanner',
            subtitle: 'Scan QR codes with your camera',
            accentColor: AppColors.accentCyan,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<QrScannerScreen>(
                builder: (_) => const QrScannerScreen(),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingMD),
          _ToolCard(
            icon: Icons.qr_code_2_rounded,
            title: 'QR Generator',
            subtitle: 'Create QR codes from text or URL',
            accentColor: AppColors.warning,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<QrGeneratorScreen>(
                builder: (_) => const QrGeneratorScreen(),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.cardSurface,
    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingLG),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(color: accentColor.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Icon(icon, color: accentColor, size: 28),
            ),
            const SizedBox(width: AppTheme.spacingMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: accentColor.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    ),
  );
}
