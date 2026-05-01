import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zenvix/core/services/storage_provider.dart';
import 'package:zenvix/core/services/storage_service.dart';
import 'package:zenvix/core/theme/app_colors.dart';
import 'package:zenvix/core/theme/app_theme.dart';
import 'package:zenvix/shared/widgets/error_snackbar.dart';

/// Result returned from [showSaveLocationSheet].
class SaveLocationChoice {
  const SaveLocationChoice({
    required this.directoryPath,
    required this.location,
  });

  final String directoryPath;
  final SaveLocation location;
}

/// Shows a bottom sheet letting the user choose between the default Zenvix
/// folder or a custom directory.
///
/// Returns a [SaveLocationChoice] or `null` if the user cancels.
Future<SaveLocationChoice?> showSaveLocationSheet(
  BuildContext context,
  WidgetRef ref, {
  /// Pre-selected file name shown as context (optional).
  String? fileName,
}) => showModalBottomSheet<SaveLocationChoice>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _SaveLocationSheet(fileName: fileName, ref: ref),
  );

// ── Internal sheet ────────────────────────────────────────────────────────────

class _SaveLocationSheet extends ConsumerStatefulWidget {
  const _SaveLocationSheet({this.fileName, required this.ref});

  final String? fileName;

  // We forward the outer WidgetRef so that preference mutations survive the
  // bottom-sheet's own ProviderScope if any.
  final WidgetRef ref;

  @override
  ConsumerState<_SaveLocationSheet> createState() => _SaveLocationSheetState();
}

class _SaveLocationSheetState extends ConsumerState<_SaveLocationSheet> {
  bool _isPickingDirectory = false;

  // ── Actions ───────────────────────────────────────────────────────────

  Future<void> _chooseDefault(BuildContext ctx) async {
    final storage = ref.read(storageServiceProvider);
    try {
      final dir = await storage.getDefaultZenvixDirectory();
      if (ctx.mounted) {
        Navigator.of(ctx).pop(
          SaveLocationChoice(
            directoryPath: dir.path,
            location: SaveLocation.defaultZenvix,
          ),
        );
      }
    } on Exception catch (e) {
      if (ctx.mounted) {
        showErrorSnackbar(ctx, message: 'Could not resolve Zenvix folder: $e');
      }
    }
  }

  Future<void> _chooseCustom(BuildContext ctx) async {
    setState(() => _isPickingDirectory = true);
    try {
      final storage = ref.read(storageServiceProvider);
      final chosen = await storage.pickCustomDirectory();
      if (chosen == null) {
        // User cancelled the system picker.
        setState(() => _isPickingDirectory = false);
        return;
      }

      // Persist the choice for future use.
      await widget.ref
          .read(storagePreferenceProvider.notifier)
          .setCustomPath(chosen);

      if (ctx.mounted) {
        Navigator.of(ctx).pop(
          SaveLocationChoice(
            directoryPath: chosen,
            location: SaveLocation.custom,
          ),
        );
      }
    } on Exception catch (e) {
      if (ctx.mounted) {
        showErrorSnackbar(ctx, message: 'Could not open folder picker: $e');
        setState(() => _isPickingDirectory = false);
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final pref = ref.watch(storagePreferenceProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXL),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppTheme.spacingLG,
        AppTheme.spacingMD,
        AppTheme.spacingLG,
        AppTheme.spacingLG +
            MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppTheme.spacingMD),
              decoration: BoxDecoration(
                color: AppColors.surfaceBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Text(
            'Save Location',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),

          if (widget.fileName != null) ...[
            const SizedBox(height: 4),
            Text(
              widget.fileName!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const SizedBox(height: AppTheme.spacingMD),
          const Divider(color: AppColors.surfaceBorder, height: 1),
          const SizedBox(height: AppTheme.spacingMD),

          // Option 1 – Default Zenvix folder
          _LocationOption(
            icon: Icons.folder_special_rounded,
            iconColor: AppColors.neonBlue,
            title: 'Zenvix Folder',
            subtitle: 'Documents/Zenvix/',
            onTap: () => _chooseDefault(context),
          ),

          const SizedBox(height: AppTheme.spacingSM),

          // Option 2 – Custom location
          _LocationOption(
            icon: Icons.folder_open_rounded,
            iconColor: AppColors.electricPurple,
            title: 'Choose Location',
            subtitle: pref.customPath ?? 'Browse your device',
            isLoading: _isPickingDirectory,
            onTap: () => _chooseCustom(context),
          ),

          const SizedBox(height: AppTheme.spacingMD),
          const Divider(color: AppColors.surfaceBorder, height: 1),
          const SizedBox(height: AppTheme.spacingSM),

          // "Always use custom" toggle
          _AlwaysCustomToggle(outerRef: widget.ref),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _LocationOption extends StatelessWidget {
  const _LocationOption({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isLoading = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMD,
              vertical: AppTheme.spacingMD,
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: AppTheme.spacingMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSM),
                if (isLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.electricPurple,
                    ),
                  )
                else
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textTertiary,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      );
}

class _AlwaysCustomToggle extends ConsumerWidget {
  const _AlwaysCustomToggle({required this.outerRef});

  final WidgetRef outerRef;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pref = ref.watch(storagePreferenceProvider);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Always use custom location',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (pref.customPath != null)
                Text(
                  pref.customPath!,
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        Switch(
          value: pref.alwaysUseCustom && pref.customPath != null,
          onChanged: pref.customPath == null
              ? null
              : (value) {
                  outerRef
                      .read(storagePreferenceProvider.notifier)
                      .setAlwaysUseCustom(value: value);
                },
          activeThumbColor: AppColors.neonBlue,
          inactiveTrackColor: AppColors.surfaceBorder,
        ),
      ],
    );
  }
}
