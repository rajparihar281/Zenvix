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
      _DrawerItem(
        icon: Icons.delete_outline,
        label: 'Trash',
        route: '/trash',
        isCurrent: currentRoute == '/trash',
      ),
      const _DrawerItem(
        icon: Icons.favorite_outline,
        label: AppStrings.drawerFavorites,
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
      backgroundColor: AppColors.paper,
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
              color: AppColors.paper,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo / icon
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/logo/logo.png',
                      width: 52,
                      height: 52,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMD),
                  // App name
                  Text(
                    AppStrings.appName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXS),
                  Text(
                    'Multi-tool utility suite',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.slate,
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
                ).textTheme.bodySmall?.copyWith(color: AppColors.slate.withValues(alpha: 0.5)),
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
          ? AppColors.mist
          : Colors.transparent,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: ListTile(
        leading: Icon(
          item.icon,
          color: item.isCurrent
              ? AppColors.coral
              : item.enabled
              ? AppColors.slate
              : AppColors.slate.withValues(alpha: 0.4),
          size: 22,
        ),
        title: Text(
          item.label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: item.isCurrent ? FontWeight.w600 : FontWeight.w500,
            color: item.isCurrent
                ? AppColors.coral
                : item.enabled
                ? AppColors.ink
                : AppColors.slate.withValues(alpha: 0.4),
          ),
        ),
        trailing: !item.enabled
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.mist,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Text(
                  'SOON',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: AppColors.slate.withValues(alpha: 0.6),
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
        title: const Text(
          AppStrings.appName,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(AppStrings.aboutDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}
