import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenvix/core/theme/app_colors.dart';
import 'package:zenvix/core/theme/app_theme.dart';
import 'package:zenvix/features/batch_processor/application/providers/batch_provider.dart';
import 'package:zenvix/features/batch_processor/domain/models/batch_job.dart';
import 'package:zenvix/features/batch_processor/presentation/screens/batch_progress_screen.dart';

class BatchActionBar extends ConsumerWidget {
  const BatchActionBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.watch(batchProvider.notifier);
    final count = notifier.selectedPaths.length;

    if (count == 0) {
      return const SizedBox.shrink();
    }

    return AnimatedSlide(
      offset: Offset.zero,
      duration: AppTheme.animMedium,
      curve: Curves.easeOutCubic,
      child: Container(
        margin: const EdgeInsets.all(AppTheme.spacingMD),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMD,
          vertical: AppTheme.spacingSM,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
          border: Border.all(
            color: AppColors.electricPurple.withValues(alpha: 0.4),
          ),
          boxShadow: AppColors.neonGlow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingSM,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.electricPurple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Text(
                    '$count selected',
                    style: const TextStyle(
                      color: AppColors.electricPurple,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => ref.read(batchProvider.notifier).clearSelection(),
                  child: const Text(
                    'Clear',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSM),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _ActionChip(
                    icon: Icons.compress_rounded,
                    label: 'Compress',
                    color: AppColors.neonBlue,
                    onTap: () => _launch(
                      context,
                      ref,
                      BatchOperation.compress,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSM),
                  _ActionChip(
                    icon: Icons.merge_rounded,
                    label: 'Merge',
                    color: AppColors.accentCyan,
                    onTap: () => _launch(
                      context,
                      ref,
                      BatchOperation.merge,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSM),
                  _ActionChip(
                    icon: Icons.lock_rounded,
                    label: 'Protect',
                    color: AppColors.warning,
                    onTap: () => _promptPasswordAndLaunch(context, ref),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _launch(
    BuildContext context,
    WidgetRef ref,
    BatchOperation operation,
  ) {
    ref.read(batchProvider.notifier).startBatch(operation);
    Navigator.push(
      context,
      MaterialPageRoute<BatchProgressScreen>(
        builder: (_) => const BatchProgressScreen(),
      ),
    );
  }

  void _promptPasswordAndLaunch(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Set Password',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          obscureText: true,
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Password for all PDFs',
            labelStyle: TextStyle(color: AppColors.textSecondary),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.surfaceBorder),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.electricPurple),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              final password = controller.text.trim();
              if (password.isEmpty) {
                return;
              }
              ref.read(batchProvider.notifier).setProtectPassword(password);
              Navigator.pop(ctx);
              _launch(context, ref, BatchOperation.protect);
            },
            child: const Text('Protect'),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMD,
        vertical: AppTheme.spacingSM,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusRound),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}
