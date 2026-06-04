import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import 'package:zenvix/core/constants/app_strings.dart';
import 'package:zenvix/core/models/tool_definition.dart';
import 'package:zenvix/core/registry/tool_registry.dart';
import 'package:zenvix/core/theme/app_colors.dart';
import 'package:zenvix/core/theme/app_theme.dart';
import 'package:zenvix/shared/widgets/app_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  // Category → allowed extensions for the quick-open file picker
  static const Map<ToolCategory, List<String>> _categoryExtensions = {
    ToolCategory.pdf: ['pdf'],
    ToolCategory.documents: ['doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx', 'csv', 'txt', 'json', 'xml', 'md'],
    ToolCategory.utilities: [],
  };

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // ── Quick-open file picker ────────────────────────────────────────────

  Future<void> _quickOpen(ToolCategory category) async {
    final extensions = _categoryExtensions[category];
    if (extensions == null || extensions.isEmpty) {
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }

    final filePath = result.files.first.path;
    if (filePath == null || !mounted) {
      return;
    }

    final ext = p.extension(filePath).toLowerCase();
    final route = _routeForExtension(ext);
    if (route == null) {
      return;
    }

    await Navigator.pushNamed(
      context,
      route,
      arguments: {'filePath': filePath, 'fileName': p.basename(filePath)},
    );
  }

  String? _routeForExtension(String ext) {
    switch (ext) {
      case '.pdf':
        return '/pdf-viewer';
      case '.txt':
      case '.json':
      case '.xml':
      case '.md':
        return '/text-viewer';
      case '.doc':
      case '.docx':
      case '.ppt':
      case '.pptx':
      case '.xls':
      case '.xlsx':
      case '.csv':
        return '/document-preview';
      default:
        return null;
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(),
        drawer: const AppDrawer(),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHero(context)),
              SliverToBoxAdapter(
                child: _buildQuickActions(context),
              ),
              for (final category in ToolCategory.values)
                _buildCategorySection(context, category),
              const SliverToBoxAdapter(
                child: SizedBox(height: AppTheme.spacingXXL),
              ),
            ],
          ),
        ),
      );

  PreferredSizeWidget _buildAppBar() => AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Row(
          children: [
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

  // ── Hero ─────────────────────────────────────────────────────────────

  Widget _buildHero(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => AppColors.accentGradient.createShader(
                Rect.fromLTWH(0, 0, bounds.width, bounds.height),
              ),
              child: Text(
                AppStrings.appTagline,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      height: 1.25,
                      color: Colors.white,
                    ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingSM),
            Text(
              '${registeredTools.where((t) => t.isAvailable).length} tools ready',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textTertiary),
            ),
          ],
        ),
      );

  // ── Quick action open buttons ─────────────────────────────────────────

  Widget _buildQuickActions(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Open a file',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textTertiary,
                    letterSpacing: 0.5,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _QuickOpenChip(
                  label: 'PDF',
                  icon: Icons.picture_as_pdf_rounded,
                  color: AppColors.neonBlue,
                  onTap: () => _quickOpen(ToolCategory.pdf),
                ),
                const SizedBox(width: 10),
                _QuickOpenChip(
                  label: 'Word / Excel',
                  icon: Icons.description_outlined,
                  color: AppColors.electricPurple,
                  onTap: () => _quickOpen(ToolCategory.documents),
                ),
                const SizedBox(width: 10),
                _QuickOpenChip(
                  label: 'Text',
                  icon: Icons.text_snippet_outlined,
                  color: AppColors.warning,
                  onTap: () => _quickOpen(ToolCategory.documents),
                ),
              ],
            ),
          ],
        ),
      );

  // ── Category section ──────────────────────────────────────────────────

  Widget _buildCategorySection(
    BuildContext context,
    ToolCategory category,
  ) {
    final tools = registeredTools
        .where((t) => t.category == category)
        .toList();
    if (tools.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final available = tools.where((t) => t.isAvailable).toList();
    final unavailable = tools.where((t) => !t.isAvailable).toList();

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: Icon(category.icon, size: 16, color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    category.label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const Spacer(),
                  if (_categoryExtensions[category]?.isNotEmpty == true)
                    GestureDetector(
                      onTap: () => _quickOpen(category),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.surfaceBorder),
                        ),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.folder_open_outlined,
                              size: 13,
                              color: AppColors.textTertiary,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Open file',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textTertiary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Available tools list
            ...available.map(
              (tool) => _ToolRow(
                tool: tool,
                onTap: () => Navigator.pushNamed(context, tool.routePath),
              ),
            ),

            // Coming soon tools — collapsed under a toggle
            if (unavailable.isNotEmpty)
              _ComingSoonRow(tools: unavailable),
          ],
        ),
      ),
    );
  }
}

// ── Quick Open Chip ───────────────────────────────────────────────────────

class _QuickOpenChip extends StatelessWidget {
  const _QuickOpenChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      );
}

// ── Tool Row ──────────────────────────────────────────────────────────────

class _ToolRow extends StatefulWidget {
  const _ToolRow({required this.tool, required this.onTap});

  final ToolDefinition tool;
  final VoidCallback onTap;

  @override
  State<_ToolRow> createState() => _ToolRowState();
}

class _ToolRowState extends State<_ToolRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final tool = widget.tool;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: AppTheme.animFast,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: _pressed
              ? tool.accentColor.withValues(alpha: 0.06)
              : AppColors.cardSurface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: _pressed
                ? tool.accentColor.withValues(alpha: 0.35)
                : AppColors.surfaceBorder.withValues(alpha: 0.6),
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: tool.accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: tool.accentColor.withValues(alpha: 0.2),
                ),
              ),
              child: Icon(tool.icon, color: tool.accentColor, size: 20),
            ),
            const SizedBox(width: 14),

            // Title + description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tool.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tool.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                      height: 1.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Chevron
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.textDisabled,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Coming Soon collapsed row ─────────────────────────────────────────────

class _ComingSoonRow extends StatefulWidget {
  const _ComingSoonRow({required this.tools});
  final List<ToolDefinition> tools;

  @override
  State<_ComingSoonRow> createState() => _ComingSoonRowState();
}

class _ComingSoonRowState extends State<_ComingSoonRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          // Toggle button
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const SizedBox(width: 2),
                  AnimatedRotation(
                    turns: _expanded ? 0.25 : 0,
                    duration: AppTheme.animFast,
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: AppColors.textDisabled,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${widget.tools.length} coming soon',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textDisabled,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expanded list
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: widget.tools
                  .map((tool) => _DisabledToolRow(tool: tool))
                  .toList(),
            ),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: AppTheme.animMedium,
          ),
        ],
      );
}

class _DisabledToolRow extends StatelessWidget {
  const _DisabledToolRow({required this.tool});
  final ToolDefinition tool;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: AppColors.surfaceBorder.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(tool.icon, color: AppColors.textDisabled, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tool.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDisabled,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tool.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textDisabled,
                      height: 1.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: const Text(
                'SOON',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDisabled,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      );
}
