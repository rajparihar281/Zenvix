import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenvix/core/constants/app_strings.dart';
import 'package:zenvix/core/theme/app_colors.dart';
import 'package:zenvix/core/theme/app_theme.dart';
import 'package:zenvix/features/image_to_pdf/providers/image_to_pdf_provider.dart';
import 'package:zenvix/features/image_to_pdf/screens/image_preview_screen.dart';
import 'package:zenvix/shared/widgets/error_snackbar.dart';

class ImageToPdfScreen extends ConsumerStatefulWidget {
  const ImageToPdfScreen({super.key});

  @override
  ConsumerState<ImageToPdfScreen> createState() => _ImageToPdfScreenState();
}

class _ImageToPdfScreenState extends ConsumerState<ImageToPdfScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(imageToPdfProvider);

    // Listen for errors
    ref.listen<ImageToPdfState>(imageToPdfProvider, (prev, next) {
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
        showErrorSnackbar(context, message: next.errorMessage!);
        ref.read(imageToPdfProvider.notifier).clearError();
      }
    });

    // If images are already selected, go straight to preview
    if (state.images.isNotEmpty) {
      return const ImagePreviewScreen();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.imageToPdf),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            ref.read(imageToPdfProvider.notifier).reset();
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Pulsing add button
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) =>
                  Transform.scale(scale: _pulseAnimation.value, child: child),
              child: GestureDetector(
                onTap: () => _showSourcePicker(context),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.accentGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.neonBlue.withValues(alpha: 0.3),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    size: 48,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingLG),
            Text(
              AppStrings.emptyImagesTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spacingSM),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingXL,
              ),
              child: Text(
                AppStrings.emptyImagesSubtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSourcePicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXL),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spacingMD,
            AppTheme.spacingSM,
            AppTheme.spacingMD,
            AppTheme.spacingMD,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppTheme.spacingMD),
              Text(
                AppStrings.addImages,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppTheme.spacingMD),
              _SourceOption(
                icon: Icons.photo_library_outlined,
                label: AppStrings.pickFromGallery,
                color: AppColors.neonBlue,
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(imageToPdfProvider.notifier).addFromGallery();
                },
              ),
              _SourceOption(
                icon: Icons.folder_open_outlined,
                label: AppStrings.pickFromFiles,
                color: AppColors.electricPurple,
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(imageToPdfProvider.notifier).addFromFileManager();
                },
              ),
              _SourceOption(
                icon: Icons.camera_alt_outlined,
                label: AppStrings.pickFromCamera,
                color: AppColors.accentCyan,
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

/// A single row in the source picker bottom sheet.
class _SourceOption extends StatelessWidget {
  const _SourceOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Icon(icon, color: color, size: 22),
    ),
    title: Text(
      label,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
    ),
    trailing: const Icon(
      Icons.chevron_right_rounded,
      color: AppColors.textTertiary,
      size: 20,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
    ),
    onTap: onTap,
  );
}
