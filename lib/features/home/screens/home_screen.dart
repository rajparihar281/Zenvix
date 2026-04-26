import 'package:flutter/material.dart';

import 'package:zenvix/core/constants/app_strings.dart';
import 'package:zenvix/core/registry/tool_registry.dart';
import 'package:zenvix/core/theme/app_colors.dart';
import 'package:zenvix/core/theme/app_theme.dart';
import 'package:zenvix/shared/widgets/app_drawer.dart';
import 'package:zenvix/shared/widgets/tool_card.dart';

/// The main hub — displays the tool grid and app tagline.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: _buildAppBar(),
    drawer: const AppDrawer(),
    body: FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppTheme.spacingXXL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroSection(context),
            const SizedBox(height: AppTheme.spacingLG),
            _buildToolGrid(context),
          ],
        ),
      ),
    ),
  );

  PreferredSizeWidget _buildAppBar() => AppBar(
    backgroundColor: AppColors.background,
    elevation: 0,
    title: Row(
      children: [
        // Animated logo
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.accentGradient,
          ),
          child: const Icon(
            Icons.construction_rounded,
            color: Colors.black,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        const Text(AppStrings.appName),
      ],
    ),
    leading: Builder(
      builder: (context) => IconButton(
        icon: const Icon(Icons.menu_rounded, size: 26),
        onPressed: () => Scaffold.of(context).openDrawer(),
      ),
    ),
    actions: [
      IconButton(
        icon: const Icon(Icons.folder_outlined, size: 24),
        tooltip: AppStrings.myFiles,
        onPressed: () => Navigator.pushNamed(context, '/my-files'),
      ),
      const SizedBox(width: 8),
    ],
  );

  Widget _buildHeroSection(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppTheme.spacingMD + 4,
      AppTheme.spacingMD,
      AppTheme.spacingMD + 4,
      0,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Gradient tagline
        ShaderMask(
          shaderCallback: (bounds) => AppColors.accentGradient.createShader(
            Rect.fromLTWH(0, 0, bounds.width, bounds.height),
          ),
          child: Text(
            AppStrings.appTagline,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              height: 1.25,
              color: Colors.white, // Gets masked by shader
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingSM),
        Text(
          '${registeredTools.where((t) => t.isAvailable).length} tools ready  ·  '
          '${registeredTools.where((t) => !t.isAvailable).length} more on the way',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
        ),
      ],
    ),
  );

  Widget _buildToolGrid(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMD),
    child: GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppTheme.spacingSM + 4,
        crossAxisSpacing: AppTheme.spacingSM + 4,
        childAspectRatio: 0.92,
      ),
      itemCount: registeredTools.length,
      itemBuilder: (context, index) {
        final tool = registeredTools[index];
        return ToolCard(
          tool: tool,
          onTap: () {
            Navigator.pushNamed(context, tool.routePath);
          },
        );
      },
    ),
  );
}
