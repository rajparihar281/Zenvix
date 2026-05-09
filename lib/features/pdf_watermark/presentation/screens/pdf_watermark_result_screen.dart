import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:zenvix/core/theme/app_colors.dart';
import 'package:zenvix/core/theme/app_theme.dart';
import 'package:zenvix/features/pdf_watermark/application/providers/pdf_watermark_provider.dart';
import 'package:zenvix/shared/widgets/error_snackbar.dart';
import 'package:zenvix/shared/widgets/neon_button.dart';

class PdfWatermarkResultScreen extends ConsumerWidget {
  const PdfWatermarkResultScreen({super.key});

  Future<void> _showSaveDialog(BuildContext context, WidgetRef ref) async {
    final state = ref.read(pdfWatermarkProvider);
    final base = state.originalFileName?.replaceAll('.pdf', '') ?? 'file';
    final controller = TextEditingController(text: '${base}_watermarked');

    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Save Watermarked PDF',
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
              borderSide: BorderSide(color: AppColors.accentCyan),
            ),
          ),
          autofocus: true,
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
              backgroundColor: AppColors.accentCyan,
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) {
                return;
              }
              Navigator.pop(ctx);
              final savedPath = await ref
                  .read(pdfWatermarkProvider.notifier)
                  .saveToDevice(name);
              if (context.mounted && savedPath != null) {
                showSuccessSnackbar(context, message: 'Saved to: $savedPath');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pdfWatermarkProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          ref.read(pdfWatermarkProvider.notifier).reset();
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Watermark Applied'),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, size: 22),
            onPressed: () {
              ref.read(pdfWatermarkProvider.notifier).reset();
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
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accentCyan.withValues(alpha: 0.1),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentCyan.withValues(alpha: 0.2),
                        blurRadius: 30,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.branding_watermark_rounded,
                    size: 52,
                    color: AppColors.accentCyan,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLG),
                Text(
                  'Watermark Applied!',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingSM),
                Text(
                  state.originalFileName ?? '',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppTheme.spacingXL),
                NeonButton(
                  label: 'Share',
                  icon: Icons.share_rounded,
                  onPressed: () async {
                    if (state.outputPath != null) {
                      try {
                        await Share.shareXFiles(
                          [XFile(state.outputPath!)],
                          text: 'Watermarked with Zenvix',
                        );
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
                    ref.read(pdfWatermarkProvider.notifier).reset();
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
                    ref.read(pdfWatermarkProvider.notifier).reset();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    Navigator.pushNamed(context, '/pdf-watermark');
                  },
                  child: const Text(
                    'Watermark Another',
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
