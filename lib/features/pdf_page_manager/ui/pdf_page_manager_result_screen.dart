import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import 'package:zenvix/core/constants/app_strings.dart';
import 'package:zenvix/core/services/storage_provider.dart';
import 'package:zenvix/core/services/storage_service.dart';
import 'package:zenvix/core/theme/app_colors.dart';
import 'package:zenvix/core/theme/app_theme.dart';
import 'package:zenvix/features/pdf_page_manager/state/pdf_page_manager_state.dart';
import 'package:zenvix/shared/widgets/error_snackbar.dart';
import 'package:zenvix/shared/widgets/neon_button.dart';
import 'package:zenvix/shared/widgets/save_location_sheet.dart';

class PdfPageManagerResultScreen extends ConsumerWidget {
  const PdfPageManagerResultScreen({super.key});

  Future<void> _handleSave(BuildContext context, WidgetRef ref) async {
    final state = ref.read(pdfPageManagerProvider);
    final defaultName =
        state.originalPdfName?.replaceAll('.pdf', '_edited') ??
        'Zenvix_Edited_${DateTime.now().millisecondsSinceEpoch}';

    final nameController = TextEditingController(text: defaultName);

    // 1 ── Ask for a file name.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'File Name',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: nameController,
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
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.electricPurple,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Next', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    final name = nameController.text.trim();
    if (confirmed != true || name.isEmpty || !context.mounted) {
      return;
    }

    // 2 ── Choose save location.
    final pref = ref.read(storagePreferenceProvider);
    String directoryPath;
    SaveLocation location;

    if (pref.alwaysUseCustom && pref.customPath != null) {
      directoryPath = pref.customPath!;
      location = SaveLocation.custom;
    } else {
      final choice = await showSaveLocationSheet(
        context,
        ref,
        fileName: '$name.pdf',
      );
      if (choice == null || !context.mounted) {
        return;
      }
      directoryPath = choice.directoryPath;
      location = choice.location;
    }

    // 3 ── Save.
    final savedPath = await ref
        .read(pdfPageManagerProvider.notifier)
        .savePdfTo(
          desiredName: name,
          directoryPath: directoryPath,
          location: location,
        );

    if (!context.mounted) {
      return;
    }
    if (savedPath != null) {
      final label = location == SaveLocation.defaultZenvix
          ? 'Saved to Documents/Zenvix/'
          : 'Saved to $savedPath';
      showSuccessSnackbar(context, message: label);
    } else {
      final err = ref.read(pdfPageManagerProvider).errorMessage;
      showErrorSnackbar(context, message: err ?? 'Save failed.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pdfPageManagerProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          ref.read(pdfPageManagerProvider.notifier).reset();
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Export Result'),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, size: 22),
            onPressed: () {
              ref.read(pdfPageManagerProvider.notifier).reset();
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
                  'PDF Saved Successfully',
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
                        await Share.shareXFiles(
                          [XFile(state.outputPath!)],
                          text: 'Edited with Zenvix',
                        );
                      } on Exception catch (e) {
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
                  onPressed: () => _handleSave(context, ref),
                  icon: const Icon(Icons.save_alt_rounded, size: 18),
                  label: const Text(AppStrings.saveToDisk),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSM),

                TextButton(
                  onPressed: () {
                    ref.read(pdfPageManagerProvider.notifier).reset();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    Navigator.pushNamed(context, '/pdf-page-manager');
                  },
                  child: const Text(
                    'Manage Another PDF',
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
