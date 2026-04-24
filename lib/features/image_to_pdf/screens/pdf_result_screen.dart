import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/widgets/neon_button.dart';
import '../../../shared/widgets/error_snackbar.dart';
import '../providers/image_to_pdf_provider.dart';

/// Post-conversion result screen with save/share/convert-another actions.
class PdfResultScreen extends ConsumerWidget {
  const PdfResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(imageToPdfProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          ref.read(imageToPdfProvider.notifier).reset();
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Result'),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, size: 22),
            onPressed: () {
              ref.read(imageToPdfProvider.notifier).reset();
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
                // Success icon with glow
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
                  AppStrings.pdfGenerated,
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

                // Share button
                NeonButton(
                  label: AppStrings.share,
                  icon: Icons.share_rounded,
                  onPressed: () async {
                    if (state.outputPath != null) {
                      try {
                        await Share.shareXFiles([
                          XFile(state.outputPath!),
                        ], text: 'Created with Zenvix');
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

                // Save confirmation
                OutlinedButton.icon(
                  onPressed: () {
                    showSuccessSnackbar(
                      context,
                      message: 'PDF saved to: ${state.outputPath}',
                    );
                  },
                  icon: const Icon(Icons.save_alt_rounded, size: 18),
                  label: const Text(AppStrings.saveToDisk),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSM),

                // Convert another
                TextButton(
                  onPressed: () {
                    ref.read(imageToPdfProvider.notifier).reset();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    Navigator.pushNamed(context, '/image-to-pdf');
                  },
                  child: const Text(
                    AppStrings.convertAnother,
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
