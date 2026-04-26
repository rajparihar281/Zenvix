import 'package:flutter/material.dart';

import 'package:zenvix/core/constants/app_strings.dart';
import 'package:zenvix/core/theme/app_colors.dart';
import 'package:zenvix/core/theme/app_theme.dart';

/// Specification for a single drawer menu item.
class _DrawerItem {
  const _DrawerItem({
    required this.icon,
    required this.label,
    this.route,
    this.enabled = true,
    this.isCurrent = false,
  });
  final IconData icon;
  final String label;
  final String? route;
  final bool enabled;
  final bool isCurrent;
}

/// Premium OLED drawer with gradient header, menu items, and footer.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, this.currentRoute = '/'});
  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    final items = [
      _DrawerItem(
        icon: Icons.home_outlined,
        label: AppStrings.drawerHome,
        route: '/',
        isCurrent: currentRoute == '/',
      ),
      const _DrawerItem(
        icon: Icons.grid_view_outlined,
        label: AppStrings.drawerAllTools,
        route: '/',
      ),
      _DrawerItem(
        icon: Icons.folder_outlined,
        label: AppStrings.myFiles,
        route: '/my-files',
        isCurrent: currentRoute == '/my-files',
      ),
      const _DrawerItem(
        icon: Icons.favorite_outline,
        label: AppStrings.drawerFavorites,
        enabled: false,
      ),
      const _DrawerItem(
        icon: Icons.settings_outlined,
        label: AppStrings.drawerSettings,
        enabled: false,
      ),
      const _DrawerItem(
        icon: Icons.info_outline,
        label: AppStrings.drawerAbout,
        route: '/about',
      ),
    ];

    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacingLG,
                AppTheme.spacingXL,
                AppTheme.spacingLG,
                AppTheme.spacingLG,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0A0A1A), Color(0xFF000000)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo / icon
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.accentGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.neonBlue.withValues(alpha: 0.3),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.construction_rounded,
                      color: Colors.black,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMD),
                  // App name
                  Text(
                    AppStrings.appName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXS),
                  Text(
                    'Multi-tool utility suite',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // ── Menu Items ──────────────────────────────────────────────
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  vertical: AppTheme.spacingSM,
                  horizontal: AppTheme.spacingSM,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _buildMenuItem(context, item);
                },
              ),
            ),

            // ── Footer ─────────────────────────────────────────────────
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMD),
              child: Text(
                'v${AppStrings.appVersion}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textDisabled),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, _DrawerItem item) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Material(
      color: item.isCurrent
          ? AppColors.neonBlue.withValues(alpha: 0.08)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: ListTile(
        leading: Icon(
          item.icon,
          color: item.isCurrent
              ? AppColors.neonBlue
              : item.enabled
              ? AppColors.textSecondary
              : AppColors.textDisabled,
          size: 22,
        ),
        title: Text(
          item.label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: item.isCurrent ? FontWeight.w600 : FontWeight.w500,
            color: item.isCurrent
                ? AppColors.neonBlue
                : item.enabled
                ? AppColors.textPrimary
                : AppColors.textDisabled,
          ),
        ),
        trailing: !item.enabled
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: const Text(
                  'SOON',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDisabled,
                    letterSpacing: 1,
                  ),
                ),
              )
            : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        onTap: item.enabled && item.route != null
            ? () {
                Navigator.pop(context); // close drawer
                if (item.route != currentRoute) {
                  if (item.route == '/about') {
                    _showAboutDialog(context);
                  } else {
                    Navigator.pushReplacementNamed(context, item.route!);
                  }
                }
              }
            : null,
      ),
    ),
  );

  void _showAboutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.appName),
        content: const Text(AppStrings.aboutDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: AppColors.neonBlue),
            ),
          ),
        ],
      ),
    );
  }
}
