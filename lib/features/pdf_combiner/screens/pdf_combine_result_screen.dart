import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/widgets/neon_button.dart';
import '../../../shared/widgets/error_snackbar.dart';
import '../providers/pdf_combiner_provider.dart';

class PdfCombineResultScreen extends ConsumerWidget {
  const PdfCombineResultScreen({super.key});

  Future<void> _showSaveDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(
      text: 'Merged_PDF_${DateTime.now().millisecondsSinceEpoch}',
    );

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'Save PDF',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'File Name',
              suffixText: '.pdf',
              labelStyle: const TextStyle(color: AppColors.textSecondary),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.surfaceBorder),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.electricPurple),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.electricPurple,
              ),
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(context); // close dialog

                final savedPath = await ref
                    .read(pdfCombinerProvider.notifier)
                    .saveMergedPdf(name);
                if (context.mounted && savedPath != null) {
                  showSuccessSnackbar(context, message: 'Saved to: $savedPath');
                }
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pdfCombinerProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          ref.read(pdfCombinerProvider.notifier).reset();
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Merge Result'),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, size: 22),
            onPressed: () {
              ref.read(pdfCombinerProvider.notifier).reset();
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
                  AppStrings.mergeSuccess,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingSM),
                if (state.outputPath != null)
                  Text(
                    state.outputPath!.split('/').last,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: AppTheme.spacingXL),

                NeonButton(
                  label: AppStrings.share,
                  icon: Icons.share_rounded,
                  onPressed: () async {
                    if (state.outputPath != null) {
                      try {
                        await Share.shareXFiles([
                          XFile(state.outputPath!),
                        ], text: 'Merged with Zenvix');
                      } catch (e) {
                        if (context.mounted) {
                          showErrorSnackbar(
                            context,
                            message: 'Share failed: $e',
                          );
                        }
                      }
                    }
                  },
                ),
                const SizedBox(height: AppTheme.spacingSM),
                OutlinedButton.icon(
                  onPressed: () => _showSaveDialog(context, ref),
                  icon: const Icon(Icons.save_alt_rounded, size: 18),
                  label: const Text(AppStrings.saveToDisk),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSM),
                TextButton(
                  onPressed: () {
                    ref.read(pdfCombinerProvider.notifier).reset();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    Navigator.pushNamed(context, '/pdf-combiner');
                  },
                  child: const Text(
                    AppStrings.mergeAnother,
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
