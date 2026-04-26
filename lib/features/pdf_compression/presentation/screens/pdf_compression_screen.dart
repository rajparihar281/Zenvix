import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenvix/core/theme/app_colors.dart';
import 'package:zenvix/core/theme/app_theme.dart';
import 'package:zenvix/features/pdf_compression/application/providers/pdf_compression_provider.dart';
import 'package:zenvix/features/pdf_compression/domain/models/compression_options.dart';
import 'package:zenvix/features/pdf_compression/presentation/screens/pdf_compression_result_screen.dart';
import 'package:zenvix/shared/widgets/error_snackbar.dart';
import 'package:zenvix/shared/widgets/neon_button.dart';

/// Main screen for the PDF Compression tool.
class PdfCompressionScreen extends ConsumerWidget {
  const PdfCompressionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pdfCompressionProvider);
    final notifier = ref.read(pdfCompressionProvider.notifier);

    // Listen for errors.
    ref.listen<PdfCompressionState>(pdfCompressionProvider, (prev, next) {
      if (next.errorMessage != null &&
          prev?.errorMessage != next.errorMessage) {
        showErrorSnackbar(context, message: next.errorMessage!);
        notifier.clearError();
      }
      if (next.status == CompressionStatus.done &&
          next.compressedData != null) {
        Navigator.push(
          context,
          MaterialPageRoute<PdfCompressionResultScreen>(
            builder: (_) => const PdfCompressionResultScreen(),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('PDF Compression'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            notifier.reset();
            Navigator.pop(context);
          },
        ),
      ),
      body: state.pdfData == null
          ? _buildEmptyState(context, notifier, state)
          : _buildConfigView(context, state, notifier),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    PdfCompressionNotifier notifier,
    PdfCompressionState state,
  ) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.success.withValues(alpha: 0.1),
          ),
          child: const Icon(
            Icons.compress_rounded,
            size: 48,
            color: AppColors.success,
          ),
        ),
        const SizedBox(height: AppTheme.spacingLG),
        Text(
          'Select a PDF to compress',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.spacingSM),
        Text(
          'Reduce file size while preserving quality',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.spacingXL),
        NeonButton(
          label: 'Select PDF',
          icon: Icons.upload_file_rounded,
          expanded: false,
          isLoading: state.status == CompressionStatus.loading,
          onPressed: notifier.pickPdf,
        ),
      ],
    ),
  );

  Widget _buildConfigView(
    BuildContext context,
    PdfCompressionState state,
    PdfCompressionNotifier notifier,
  ) => Column(
    children: [
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── File info card ──
              _FileInfoCard(state: state),
              const SizedBox(height: AppTheme.spacingLG),

              // ── Compression level selector ──
              Text(
                'Compression Level',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppTheme.spacingSM),
              _CompressionLevelSelector(
                selected: state.level,
                onChanged: notifier.setLevel,
              ),
              const SizedBox(height: AppTheme.spacingLG),

              // ── Size preview ──
              _SizePreviewCard(state: state),
            ],
          ),
        ),
      ),

      // ── Bottom action bar ──
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMD),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state.status == CompressionStatus.compressing) ...[
                _ProgressBar(progress: state.progress),
                const SizedBox(height: AppTheme.spacingSM),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: notifier.pickPdf,
                      icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                      label: const Text('Change File'),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSM),
                  Expanded(
                    child: NeonButton(
                      label: 'Compress',
                      icon: Icons.compress_rounded,
                      isLoading: state.status == CompressionStatus.compressing,
                      onPressed: notifier.compress,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

// ── File Info Card ───────────────────────────────────────────────────────

class _FileInfoCard extends StatelessWidget {
  const _FileInfoCard({required this.state});

  final PdfCompressionState state;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppTheme.spacingMD),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      border: Border.all(color: AppColors.surfaceBorder),
    ),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: const Icon(
            Icons.picture_as_pdf_rounded,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: AppTheme.spacingSM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                state.originalFileName ?? 'Unknown',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(color: AppColors.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                state.formatBytes(state.originalSize),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ── Compression Level Selector ───────────────────────────────────────────

class _CompressionLevelSelector extends StatelessWidget {
  const _CompressionLevelSelector({
    required this.selected,
    required this.onChanged,
  });

  final CompressionLevel selected;
  final ValueChanged<CompressionLevel> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: CompressionLevel.values.map((level) {
      final isSelected = level == selected;
      return Expanded(
        child: Padding(
          padding: EdgeInsets.only(
            right: level != CompressionLevel.values.last ? 8 : 0,
          ),
          child: GestureDetector(
            onTap: () => onChanged(level),
            child: AnimatedContainer(
              duration: AppTheme.animFast,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.success.withValues(alpha: 0.15)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(
                  color: isSelected
                      ? AppColors.success
                      : AppColors.surfaceBorder,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _iconFor(level),
                    size: 22,
                    color: isSelected
                        ? AppColors.success
                        : AppColors.textTertiary,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    level.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isSelected
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList(),
  );

  IconData _iconFor(CompressionLevel level) {
    switch (level) {
      case CompressionLevel.low:
        return Icons.compress_rounded;
      case CompressionLevel.medium:
        return Icons.speed_rounded;
      case CompressionLevel.high:
        return Icons.bolt_rounded;
    }
  }
}

// ── Size Preview ─────────────────────────────────────────────────────────

class _SizePreviewCard extends StatelessWidget {
  const _SizePreviewCard({required this.state});

  final PdfCompressionState state;

  @override
  Widget build(BuildContext context) {
    final savingsPercent = state.originalSize > 0
        ? ((1 - state.estimatedSize / state.originalSize) * 100).round()
        : 0;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sizeColumn(
                context,
                'Original',
                state.formatBytes(state.originalSize),
                AppColors.textSecondary,
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.textTertiary,
                size: 20,
              ),
              _sizeColumn(
                context,
                'Estimated',
                state.formatBytes(state.estimatedSize),
                AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSM),
          const Divider(),
          const SizedBox(height: AppTheme.spacingSM),
          Text(
            '~$savingsPercent% size reduction',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sizeColumn(
    BuildContext context,
    String label,
    String size,
    Color color,
  ) => Column(
    children: [
      Text(label, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 4),
      Text(
        size,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

// ── Progress Bar ─────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Compressing…', style: Theme.of(context).textTheme.bodySmall),
          Text(
            '${(progress * 100).round()}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: progress,
          minHeight: 6,
          backgroundColor: AppColors.surfaceLight,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
        ),
      ),
    ],
  );
}
