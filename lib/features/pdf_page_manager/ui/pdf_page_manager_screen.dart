import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:zenvix/core/theme/app_colors.dart';
import 'package:zenvix/core/theme/app_theme.dart';
import 'package:zenvix/features/pdf_page_manager/state/pdf_page_manager_state.dart';
import 'package:zenvix/features/pdf_page_manager/ui/pdf_page_manager_result_screen.dart';
import 'package:zenvix/shared/widgets/error_snackbar.dart';
import 'package:zenvix/shared/widgets/neon_button.dart';

class PdfPageManagerScreen extends ConsumerWidget {
  const PdfPageManagerScreen({super.key});

  Future<void> _showSaveDialog(BuildContext context, WidgetRef ref) async {
    final state = ref.read(pdfPageManagerProvider);
    final baseName =
        state.originalPdfName?.replaceAll('.pdf', '') ?? 'Edited_PDF';
    final controller = TextEditingController(
      text: '${baseName}_${DateTime.now().millisecondsSinceEpoch}',
    );

    return showDialog(
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
              if (name.isEmpty) {
                return;
              }
              Navigator.pop(context); // close dialog

              await ref.read(pdfPageManagerProvider.notifier).savePdf(name);
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pdfPageManagerProvider);
    final notifier = ref.read(pdfPageManagerProvider.notifier);

    // Listen for errors and success
    ref.listen<PdfPageManagerState>(pdfPageManagerProvider, (prev, next) {
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
        showErrorSnackbar(context, message: next.errorMessage!);
        notifier.clearError();
      }
      if (next.status == PageManagerStatus.done && next.outputPath != null) {
        Navigator.push(
          context,
          MaterialPageRoute<PdfPageManagerResultScreen>(
            builder: (_) => const PdfPageManagerResultScreen(),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Page Manager'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            notifier.reset();
            Navigator.pop(context);
          },
        ),
        actions: [
          if (state.pages.isNotEmpty)
            IconButton(
              icon: Icon(
                state.selectedPageIds.length == state.pages.length
                    ? Icons.deselect
                    : Icons.select_all,
              ),
              onPressed: () => notifier.toggleSelectAll,
              tooltip: 'Select All',
            ),
        ],
      ),
      body: _buildBody(context, ref, state, notifier),
      bottomNavigationBar: state.pages.isNotEmpty
          ? _buildBottomBar(context, ref, state, notifier)
          : null,
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    PdfPageManagerState state,
    PdfPageManagerNotifier notifier,
  ) {
    if (state.status == PageManagerStatus.loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.electricPurple),
            SizedBox(height: 16),
            Text(
              'Loading PDF pages...',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (state.pages.isEmpty) {
      return Center(
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
                Icons.picture_as_pdf_rounded,
                size: 48,
                color: AppColors.electricPurple,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLG),
            const Text(
              'No PDF Selected',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSM),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppTheme.spacingXL),
              child: Text(
                'Select a PDF to manage its pages.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
              ),
            ),
            const SizedBox(height: AppTheme.spacingLG),
            NeonButton(
              label: 'Select PDF',
              icon: Icons.file_open_outlined,
              expanded: false,
              onPressed: () => notifier.pickPdf(),
            ),
          ],
        ),
      );
    }

    return ReorderableGridView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingSM),
      itemCount: state.pages.length,
      onReorder: notifier.reorderPages,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75, // Standard PDF aspect ratio roughly
      ),
      itemBuilder: (context, index) {
        final page = state.pages[index];
        final isSelected = state.selectedPageIds.contains(page.id);

        return GestureDetector(
          key: ValueKey(page.id),
          onTap: () => notifier.togglePageSelection(page.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppColors.electricPurple
                    : AppColors.surfaceBorder,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: AppColors.electricPurple.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Center(
                    child: RotatedBox(
                      quarterTurns: page.rotationAngle ~/ 90,
                      child: Image.memory(
                        page.thumbnailData,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.rotate_right_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () => notifier.rotatePage(page.id),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppColors.error,
                          size: 20,
                        ),
                        onPressed: () => notifier.deletePage(page.id),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.electricPurple,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    WidgetRef ref,
    PdfPageManagerState state,
    PdfPageManagerNotifier notifier,
  ) {
    final hasSelection = state.selectedPageIds.isNotEmpty;

    return Container(
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasSelection)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon(
                      onPressed: () => notifier.rotateSelectedPages(),
                      icon: const Icon(
                        Icons.rotate_right_rounded,
                        color: AppColors.textPrimary,
                      ),
                      label: const Text(
                        'Rotate',
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => notifier.deleteSelectedPages(),
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.error,
                      ),
                      label: const Text(
                        'Delete',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: NeonButton(
                    label: hasSelection ? 'Extract Selected' : 'Save PDF',
                    icon: Icons.save_alt_rounded,
                    isLoading: state.status == PageManagerStatus.processing,
                    onPressed: state.pages.isEmpty
                        ? null
                        : () => _showSaveDialog(context, ref),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
