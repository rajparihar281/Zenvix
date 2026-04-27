import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:zenvix/core/theme/app_colors.dart';
import 'package:zenvix/core/theme/app_theme.dart';
import 'package:zenvix/features/pdf_compression/application/providers/pdf_compression_provider.dart';
import 'package:zenvix/shared/widgets/error_snackbar.dart';
import 'package:zenvix/shared/widgets/neon_button.dart';

/// Success screen shown after PDF compression completes.
class PdfCompressionResultScreen extends ConsumerWidget {
  const PdfCompressionResultScreen({super.key});

  Future<void> _showSaveDialog(BuildContext context, WidgetRef ref) async {
    final state = ref.read(pdfCompressionProvider);
    final baseName = state.originalFileName?.replaceAll('.pdf', '') ?? 'file';
    final controller = TextEditingController(text: '${baseName}_compressed');

    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Save Compressed PDF',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            labelText: 'File Name',
            suffixText: '.pdf',
            labelStyle: TextStyle(color: AppColors.textSecondary),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.surfaceBorder),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.success),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) {
                return;
              }
              Navigator.pop(context);

              final savedPath = await ref
                  .read(pdfCompressionProvider.notifier)
                  .saveCompressedPdf(name);
              if (context.mounted && savedPath != null) {
                showSuccessSnackbar(context, message: 'Saved to: $savedPath');
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pdfCompressionProvider);
    final savingsPercent = state.originalSize > 0
        ? ((1 - state.compressedSize / state.originalSize) * 100).round()
        : 0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          ref.read(pdfCompressionProvider.notifier).reset();
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Compression Result'),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, size: 22),
            onPressed: () {
              ref.read(pdfCompressionProvider.notifier).reset();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLG),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Success icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.success.withValues(alpha: 0.1),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withValues(alpha: 0.2),
                        blurRadius: 30,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 56,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLG),
                Text(
                  'Compression Complete!',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingSM),

                // Size comparison
                _SizeComparison(
                  originalSize: state.formatBytes(state.originalSize),
                  compressedSize: state.formatBytes(state.compressedSize),
                  savingsPercent: savingsPercent,
                ),

                const SizedBox(height: AppTheme.spacingXL),

                // Actions
                NeonButton(
                  label: 'Share',
                  icon: Icons.share_rounded,
                  onPressed: () async {
                    if (state.outputPath != null) {
                      try {
                        await Share.shareXFiles([
                          XFile(state.outputPath!),
                        ], text: 'Compressed with Zenvix');
                      } on Exception catch (e) {
                        if (context.mounted) {
                          showErrorSnackbar(
                            context,
                            message: 'Share failed: $e',
                          );
                        }
                      }
                    } else {
                      await _showSaveDialog(context, ref);
                    }
                  },
                ),
                const SizedBox(height: AppTheme.spacingSM),
                OutlinedButton.icon(
                  onPressed: () => _showSaveDialog(context, ref),
                  icon: const Icon(Icons.save_alt_rounded, size: 18),
                  label: const Text('Save to Device'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSM),
                OutlinedButton.icon(
                  onPressed: () {
                    ref.read(pdfCompressionProvider.notifier).reset();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    Navigator.pushNamed(context, '/my-files');
                  },
                  icon: const Icon(Icons.folder_open_rounded, size: 18),
                  label: const Text('Go to Folder'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSM),
                TextButton(
                  onPressed: () {
                    ref.read(pdfCompressionProvider.notifier).reset();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    Navigator.pushNamed(context, '/pdf-compression');
                  },
                  child: const Text(
                    'Compress Another',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Size Comparison Widget ───────────────────────────────────────────────

class _SizeComparison extends StatelessWidget {
  const _SizeComparison({
    required this.originalSize,
    required this.compressedSize,
    required this.savingsPercent,
  });

  final String originalSize;
  final String compressedSize;
  final int savingsPercent;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: AppTheme.spacingSM),
    padding: const EdgeInsets.all(AppTheme.spacingMD),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      border: Border.all(color: AppColors.surfaceBorder),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _sizeColumn(context, 'Original', originalSize, AppColors.textSecondary),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.success.withValues(alpha: 0.15),
          ),
          child: Center(
            child: Text(
              '-$savingsPercent%',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.success,
              ),
            ),
          ),
        ),
        _sizeColumn(context, 'Compressed', compressedSize, AppColors.success),
      ],
    ),
  );

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
