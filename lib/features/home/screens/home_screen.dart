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
    ToolCategory.documents: [
      'txt',
      'json',
      'xml',
      'md',
    ],
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
      default:
        return null;
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.paper,
    appBar: _buildAppBar(),
    drawer: const AppDrawer(),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => _quickOpen(ToolCategory.pdf),
      icon: const Icon(Icons.add_rounded),
      label: const Text('Open PDF'),
    ),
    body: FadeTransition(
      opacity: _fadeAnimation,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHero(context)),
          for (final category in ToolCategory.values)
            _buildCategorySection(context, category),
          const SliverToBoxAdapter(
            child: SizedBox(height: AppTheme.spacingXXL * 2), // Extra space for FAB
          ),
        ],
      ),
    ),
  );

  PreferredSizeWidget _buildAppBar() => AppBar(
    backgroundColor: AppColors.paper,
    elevation: 0,
    title: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'assets/logo/logo.png',
            width: 32,
            height: 32,
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          AppStrings.appName,
          style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold),
        ),
      ],
    ),
    leading: Builder(
      builder: (context) => IconButton(
        icon: const Icon(Icons.menu_rounded, size: 26, color: AppColors.ink),
        onPressed: () => Scaffold.of(context).openDrawer(),
      ),
    ),
    actions: [
      IconButton(
        icon: const Icon(Icons.folder_outlined, size: 24, color: AppColors.ink),
        tooltip: AppStrings.myFiles,
        onPressed: () => Navigator.pushNamed(context, '/my-files'),
      ),
      const SizedBox(width: 8),
    ],
  );

  // ── Hero ─────────────────────────────────────────────────────────────

  Widget _buildHero(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your PDFs',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
            fontSize: 36,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Manage and edit documents seamlessly.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.slate,
          ),
        ),
      ],
    ),
  );

  // ── Category section ──────────────────────────────────────────────────

  Widget _buildCategorySection(BuildContext context, ToolCategory category) {
    final tools = registeredTools.where((t) => t.category == category).toList();
    if (tools.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final available = tools.where((t) => t.isAvailable).toList();
    final unavailable = tools.where((t) => !t.isAvailable).toList();

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    category.label.toUpperCase(),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate,
                      letterSpacing: 1.2,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  if (_categoryExtensions[category]?.isNotEmpty == true)
                    GestureDetector(
                      onTap: () => _quickOpen(category),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                          boxShadow: AppColors.subtleElevation,
                        ),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.folder_open_outlined,
                              size: 14,
                              color: AppColors.ink,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Open',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.ink,
                                fontWeight: FontWeight.w600,
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
            if (unavailable.isNotEmpty) _ComingSoonRow(tools: unavailable),
          ],
        ),
      ),
    );
  }
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
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _pressed ? AppColors.mist : AppColors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: _pressed ? AppColors.slate.withValues(alpha: 0.3) : AppColors.border,
          ),
          boxShadow: _pressed ? [] : AppColors.subtleElevation,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.mist,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(tool.icon, color: AppColors.ink, size: 22),
            ),
            const SizedBox(width: 16),

            // Title + description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tool.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    tool.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.slate,
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
              size: 20,
              color: AppColors.slate,
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              AnimatedRotation(
                turns: _expanded ? 0.25 : 0,
                duration: AppTheme.animFast,
                child: const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.slate,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${widget.tools.length} coming soon',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.slate,
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
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: AppColors.white.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
    ),
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.mist.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(tool.icon, color: AppColors.slate.withValues(alpha: 0.5), size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tool.title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                tool.description,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.slate.withValues(alpha: 0.5),
                  height: 1.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.mist,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'SOON',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.slate,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ],
    ),
  );
}
