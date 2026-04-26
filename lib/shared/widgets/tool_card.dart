import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:zenvix/core/models/tool_definition.dart';
import 'package:zenvix/core/theme/app_colors.dart';
import 'package:zenvix/core/theme/app_theme.dart';

/// Premium feature card rendered from a [ToolDefinition].
///
/// Shows icon, title, description, and a "Coming Soon" badge
/// for tools that are not yet available.  Animates border glow on press.
class ToolCard extends StatefulWidget {
  const ToolCard({super.key, required this.tool, this.onTap});
  final ToolDefinition tool;
  final VoidCallback? onTap;

  @override
  State<ToolCard> createState() => _ToolCardState();
}

class _ToolCardState extends State<ToolCard>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final tool = widget.tool;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        if (tool.isAvailable) {
          widget.onTap?.call();
        }
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: AppTheme.animFast,
        curve: Curves.easeOut,
        transform: Matrix4.identity()
          ..scaleByVector3(
            Vector3(
              _isPressed ? 0.96 : 1.0,
              _isPressed ? 0.96 : 1.0,
              _isPressed ? 0.96 : 1.0,
            ),
          ),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(
            color: _isPressed && tool.isAvailable
                ? tool.accentColor.withValues(alpha: 0.5)
                : AppColors.surfaceBorder.withValues(alpha: 0.5),
          ),
          boxShadow: _isPressed && tool.isAvailable
              ? [
                  BoxShadow(
                    color: tool.accentColor.withValues(alpha: 0.15),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
              : AppColors.subtleElevation,
        ),
        child: Stack(
          children: [
            // ── Card Content ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon with gradient circle
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          tool.accentColor.withValues(alpha: 0.2),
                          tool.secondaryColor.withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: tool.accentColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(tool.icon, color: tool.accentColor, size: 24),
                  ),
                  const SizedBox(height: AppTheme.spacingSM + 4),

                  // Title
                  Text(
                    tool.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: tool.isAvailable
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppTheme.spacingXS),

                  // Description
                  Text(
                    tool.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: tool.isAvailable
                          ? AppColors.textSecondary
                          : AppColors.textDisabled,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // ── Coming Soon Badge ───────────────────────────────────────
            if (!tool.isAvailable)
              Positioned(
                top: AppTheme.spacingSM,
                right: AppTheme.spacingSM,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    border: Border.all(
                      color: AppColors.surfaceBorder,
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    'SOON',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textTertiary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
