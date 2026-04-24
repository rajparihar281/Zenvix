import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_strings.dart';
import '../../../shared/widgets/neon_button.dart';
import '../providers/image_to_pdf_provider.dart';
import 'image_editor_screen.dart';
import 'pdf_options_screen.dart';
import 'pdf_result_screen.dart';

class ImagePreviewScreen extends ConsumerWidget {
  const ImagePreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(imageToPdfProvider);
    final notifier = ref.read(imageToPdfProvider.notifier);

    ref.listen<ImageToPdfState>(imageToPdfProvider, (prev, next) {
      if (next.status == ConversionStatus.done && next.outputPath != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PdfResultScreen()),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          '${state.images.length} image${state.images.length == 1 ? '' : 's'}',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => notifier.reset(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_outlined),
            onPressed: () => _showSourcePicker(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.all(AppTheme.spacingSM),
              onReorder: notifier.reorderImages,
              itemCount: state.images.length,
              proxyDecorator: (child, idx, anim) => Material(
                color: Colors.transparent,
                elevation: 8,
                shadowColor: AppColors.neonBlue.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                child: child,
              ),
              itemBuilder: (context, i) {
                final img = state.images[i];
                return Container(
                  key: ValueKey(img.id),
                  margin: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    border: Border.all(
                      color: img.hasEdits
                          ? AppColors.neonBlue.withValues(alpha: 0.3)
                          : AppColors.surfaceBorder.withValues(alpha: 0.4),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(img.originalPath),
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 56,
                          height: 56,
                          color: AppColors.surfaceLight,
                          child: const Icon(
                            Icons.broken_image,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      'Image ${i + 1}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: img.hasEdits
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.neonBlue.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Edited',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.neonBlue,
                              ),
                            ),
                          )
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ImageEditorScreen(imageIndex: i),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: AppColors.error,
                          ),
                          onPressed: () => notifier.removeImage(i),
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
                      onPressed: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: AppColors.surface,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        builder: (_) => const PdfOptionsSheet(),
                      ),
                      icon: const Icon(Icons.tune_rounded, size: 18),
                      label: const Text(AppStrings.pdfOptions),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: NeonButton(
                      label: AppStrings.convertToPdf,
                      icon: Icons.picture_as_pdf_rounded,
                      isLoading: state.status == ConversionStatus.processing,
                      onPressed: state.images.isEmpty
                          ? null
                          : () => notifier.generatePdf(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (state.status == ConversionStatus.processing)
            LinearProgressIndicator(
              value: state.progress,
              backgroundColor: AppColors.surfaceLight,
              color: AppColors.neonBlue,
              minHeight: 3,
            ),
        ],
      ),
    );
  }

  void _showSourcePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.neonBlue,
                ),
                title: const Text(AppStrings.pickFromGallery),
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(imageToPdfProvider.notifier).addFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.folder_open_outlined,
                  color: AppColors.electricPurple,
                ),
                title: const Text(AppStrings.pickFromFiles),
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(imageToPdfProvider.notifier).addFromFileManager();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_outlined,
                  color: AppColors.accentCyan,
                ),
                title: const Text(AppStrings.pickFromCamera),
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(imageToPdfProvider.notifier).addFromCamera();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
