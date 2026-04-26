import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:zenvix/core/theme/app_colors.dart';
import 'package:zenvix/core/theme/app_theme.dart';
import 'package:zenvix/features/pdf_security/application/providers/pdf_security_provider.dart';
import 'package:zenvix/features/pdf_security/domain/models/security_options.dart';
import 'package:zenvix/shared/widgets/error_snackbar.dart';
import 'package:zenvix/shared/widgets/neon_button.dart';

/// Success screen shown after PDF security operations complete.
class PdfSecurityResultScreen extends ConsumerWidget {
  const PdfSecurityResultScreen({super.key});

  Future<void> _showSaveDialog(BuildContext context, WidgetRef ref) async {
    final state = ref.read(pdfSecurityProvider);
    final baseName = state.originalFileName?.replaceAll('.pdf', '') ?? 'file';
    final suffix = state.mode == SecurityMode.protect
        ? '_protected'
        : '_unlocked';
    final controller = TextEditingController(text: '$baseName$suffix');

    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Save PDF',
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
              if (name.isEmpty) {
                return;
              }
              Navigator.pop(context);

              final savedPath = await ref
                  .read(pdfSecurityProvider.notifier)
                  .saveProcessedPdf(name);
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
    final state = ref.watch(pdfSecurityProvider);
    final isProtected = state.mode == SecurityMode.protect;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          ref.read(pdfSecurityProvider.notifier).reset();
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(isProtected ? 'Protected' : 'Unlocked'),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, size: 22),
            onPressed: () {
              ref.read(pdfSecurityProvider.notifier).reset();
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
                    color:
                        (isProtected
                                ? AppColors.electricPurple
                                : AppColors.success)
                            .withValues(alpha: 0.1),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (isProtected
                                    ? AppColors.electricPurple
                                    : AppColors.success)
                                .withValues(alpha: 0.2),
                        blurRadius: 30,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: Icon(
                    isProtected ? Icons.lock_rounded : Icons.lock_open_rounded,
                    size: 56,
                    color: isProtected
                        ? AppColors.electricPurple
                        : AppColors.success,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLG),
                Text(
                  isProtected
                      ? 'PDF Protected Successfully!'
                      : 'PDF Unlocked Successfully!',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingSM),
                if (state.originalFileName != null)
                  Text(
                    state.originalFileName!,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
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
                        ], text: 'Secured with Zenvix');
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
                TextButton(
                  onPressed: () {
                    ref.read(pdfSecurityProvider.notifier).reset();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    Navigator.pushNamed(context, '/pdf-security');
                  },
                  child: const Text(
                    'Process Another',
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
