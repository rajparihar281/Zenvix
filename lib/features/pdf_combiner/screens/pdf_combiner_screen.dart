import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenvix/core/constants/app_strings.dart';
import 'package:zenvix/core/theme/app_colors.dart';
import 'package:zenvix/core/theme/app_theme.dart';
import 'package:zenvix/features/pdf_combiner/providers/pdf_combiner_provider.dart';
import 'package:zenvix/features/pdf_combiner/screens/pdf_combine_result_screen.dart';
import 'package:zenvix/shared/widgets/error_snackbar.dart';
import 'package:zenvix/shared/widgets/neon_button.dart';

class PdfCombinerScreen extends ConsumerWidget {
  const PdfCombinerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pdfCombinerProvider);
    final notifier = ref.read(pdfCombinerProvider.notifier);

    // Listen for errors
    ref.listen<PdfCombinerState>(pdfCombinerProvider, (prev, next) {
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
        showErrorSnackbar(context, message: next.errorMessage!);
        notifier.clearError();
      }
      if (next.status == CombineStatus.done && next.outputPath != null) {
        Navigator.push(
          context,
          MaterialPageRoute<PdfCombineResultScreen>(
            builder: (_) => const PdfCombineResultScreen(),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.pdfCombiner),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            notifier.reset();
            Navigator.pop(context);
          },
        ),
      ),
      body: state.files.isEmpty
          ? _buildEmptyState(context, notifier)
          : _buildFileList(context, ref, state, notifier),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    PdfCombinerNotifier notifier,
  ) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                AppColors.electricPurple.withValues(alpha: 0.2),
                AppColors.accentPink.withValues(alpha: 0.1),
              ],
            ),
            border: Border.all(
              color: AppColors.electricPurple.withValues(alpha: 0.3),
            ),
          ),
          child: const Icon(
            Icons.merge_type_rounded,
            size: 48,
            color: AppColors.electricPurple,
          ),
        ),
        const SizedBox(height: AppTheme.spacingLG),
        Text(
          AppStrings.emptyPdfsTitle,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSM),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXL),
          child: Text(
            AppStrings.emptyPdfsSubtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.textTertiary),
          ),
        ),
        const SizedBox(height: AppTheme.spacingLG),
        NeonButton(
          label: AppStrings.selectPdfs,
          icon: Icons.file_open_outlined,
          expanded: false,
          onPressed: () => notifier.pickPdfs(),
        ),
      ],
    ),
  );

  Widget _buildFileList(
    BuildContext context,
    WidgetRef ref,
    PdfCombinerState state,
    PdfCombinerNotifier notifier,
  ) => Column(
    children: [
      Expanded(
        child: ReorderableListView.builder(
          padding: const EdgeInsets.all(AppTheme.spacingSM),
          onReorder: notifier.reorderFiles,
          itemCount: state.files.length,
          proxyDecorator: (child, idx, anim) => Material(
            color: Colors.transparent,
            elevation: 8,
            shadowColor: AppColors.electricPurple.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            child: child,
          ),
          itemBuilder: (context, i) {
            final file = state.files[i];
            return Container(
              key: ValueKey(file.id),
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(
                  color: AppColors.surfaceBorder.withValues(alpha: 0.4),
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.electricPurple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf_rounded,
                    color: AppColors.electricPurple,
                    size: 22,
                  ),
                ),
                title: Text(
                  file.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  file.formattedSize,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: AppColors.error,
                      ),
                      onPressed: () => notifier.removeFile(i),
                    ),
                    const Icon(
                      Icons.drag_handle_rounded,
                      size: 20,
                      color: AppColors.textTertiary,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),

      // Bottom bar
      Container(
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(
              color: AppColors.surfaceBorder.withValues(alpha: 0.5),
            ),
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => notifier.pickPdfs(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add More'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: NeonButton(
                  label: AppStrings.mergePdfs,
                  icon: Icons.merge_type_rounded,
                  isLoading: state.status == CombineStatus.processing,
                  onPressed: state.files.length < 2
                      ? null
                      : () => notifier.mergePdfs(),
                ),
              ),
            ],
          ),
        ),
      ),
      if (state.status == CombineStatus.processing)
        const LinearProgressIndicator(
          backgroundColor: AppColors.surfaceLight,
          color: AppColors.electricPurple,
          minHeight: 3,
        ),
    ],
  );
}
