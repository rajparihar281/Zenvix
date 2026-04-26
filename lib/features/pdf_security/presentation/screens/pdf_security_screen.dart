import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenvix/core/theme/app_colors.dart';
import 'package:zenvix/core/theme/app_theme.dart';
import 'package:zenvix/features/pdf_security/application/providers/pdf_security_provider.dart';
import 'package:zenvix/features/pdf_security/domain/models/security_options.dart';
import 'package:zenvix/features/pdf_security/presentation/screens/pdf_security_result_screen.dart';
import 'package:zenvix/shared/widgets/error_snackbar.dart';
import 'package:zenvix/shared/widgets/neon_button.dart';

/// Main screen for the PDF Security tool (protect / unlock).
class PdfSecurityScreen extends ConsumerStatefulWidget {
  const PdfSecurityScreen({super.key});

  @override
  ConsumerState<PdfSecurityScreen> createState() => _PdfSecurityScreenState();
}

class _PdfSecurityScreenState extends ConsumerState<PdfSecurityScreen> {
  final _userPasswordController = TextEditingController();
  final _ownerPasswordController = TextEditingController();
  final _unlockPasswordController = TextEditingController();
  bool _obscureUser = true;
  bool _obscureOwner = true;
  bool _obscureUnlock = true;

  @override
  void dispose() {
    _userPasswordController.dispose();
    _ownerPasswordController.dispose();
    _unlockPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pdfSecurityProvider);
    final notifier = ref.read(pdfSecurityProvider.notifier);

    // Listen for errors and completion.
    ref.listen<PdfSecurityState>(pdfSecurityProvider, (prev, next) {
      if (next.errorMessage != null &&
          prev?.errorMessage != next.errorMessage) {
        showErrorSnackbar(context, message: next.errorMessage!);
        notifier.clearError();
      }
      if (next.status == SecurityStatus.done && next.processedData != null) {
        Navigator.push(
          context,
          MaterialPageRoute<PdfSecurityResultScreen>(
            builder: (_) => const PdfSecurityResultScreen(),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('PDF Security'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            notifier.reset();
            Navigator.pop(context);
          },
        ),
      ),
      body: state.pdfData == null
          ? _buildEmptyState(context, notifier, state)
          : _buildConfigView(context, state, notifier),
    );
  }

  // ── Empty State ──────────────────────────────────────────────────────

  Widget _buildEmptyState(
    BuildContext context,
    PdfSecurityNotifier notifier,
    PdfSecurityState state,
  ) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.electricPurple.withValues(alpha: 0.1),
          ),
          child: const Icon(
            Icons.lock_rounded,
            size: 48,
            color: AppColors.electricPurple,
          ),
        ),
        const SizedBox(height: AppTheme.spacingLG),
        Text(
          'Select a PDF to secure',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.spacingSM),
        Text(
          'Add or remove password protection',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.spacingXL),
        NeonButton(
          label: 'Select PDF',
          icon: Icons.upload_file_rounded,
          expanded: false,
          isLoading: state.status == SecurityStatus.loading,
          onPressed: notifier.pickPdf,
        ),
      ],
    ),
  );

  // ── Config View ──────────────────────────────────────────────────────

  Widget _buildConfigView(
    BuildContext context,
    PdfSecurityState state,
    PdfSecurityNotifier notifier,
  ) => Column(
    children: [
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // File info
              _FileInfoTile(state: state),
              const SizedBox(height: AppTheme.spacingLG),

              // Mode selector
              _ModeSelector(
                selected: state.mode,
                onChanged: (mode) {
                  notifier.setMode(mode);
                  _userPasswordController.clear();
                  _ownerPasswordController.clear();
                  _unlockPasswordController.clear();
                },
              ),
              const SizedBox(height: AppTheme.spacingLG),

              // Mode-specific content
              if (state.mode == SecurityMode.protect) ...[
                _buildProtectFields(context, state, notifier),
              ] else ...[
                _buildUnlockFields(context),
              ],
            ],
          ),
        ),
      ),

      // Bottom action
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMD),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: notifier.pickPdf,
                  icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                  label: const Text('Change File'),
                ),
              ),
              const SizedBox(width: AppTheme.spacingSM),
              Expanded(
                child: NeonButton(
                  label: state.mode == SecurityMode.protect
                      ? 'Protect'
                      : 'Unlock',
                  icon: state.mode == SecurityMode.protect
                      ? Icons.lock_rounded
                      : Icons.lock_open_rounded,
                  isLoading: state.status == SecurityStatus.processing,
                  onPressed: () => _executeAction(notifier, state),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );

  // ── Protect Fields ───────────────────────────────────────────────────

  Widget _buildProtectFields(
    BuildContext context,
    PdfSecurityState state,
    PdfSecurityNotifier notifier,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Password', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: AppTheme.spacingSM),
      _PasswordField(
        controller: _userPasswordController,
        label: 'User Password (required)',
        obscure: _obscureUser,
        onToggle: () => setState(() => _obscureUser = !_obscureUser),
      ),
      const SizedBox(height: AppTheme.spacingSM),
      _PasswordField(
        controller: _ownerPasswordController,
        label: 'Owner Password (optional)',
        obscure: _obscureOwner,
        onToggle: () => setState(() => _obscureOwner = !_obscureOwner),
      ),
      const SizedBox(height: AppTheme.spacingLG),

      Text('Permissions', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: AppTheme.spacingSM),
      _PermissionToggle(
        icon: Icons.print_rounded,
        label: 'Allow Printing',
        value: state.permissions.allowPrinting,
        onChanged: (v) => notifier.setPermissions(
          state.permissions.copyWith(allowPrinting: v),
        ),
      ),
      _PermissionToggle(
        icon: Icons.content_copy_rounded,
        label: 'Allow Copying',
        value: state.permissions.allowCopying,
        onChanged: (v) => notifier.setPermissions(
          state.permissions.copyWith(allowCopying: v),
        ),
      ),
    ],
  );

  // ── Unlock Fields ────────────────────────────────────────────────────

  Widget _buildUnlockFields(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Password', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: AppTheme.spacingSM),
      _PasswordField(
        controller: _unlockPasswordController,
        label: 'Enter current password',
        obscure: _obscureUnlock,
        onToggle: () => setState(() => _obscureUnlock = !_obscureUnlock),
      ),
      const SizedBox(height: AppTheme.spacingSM),
      Text(
        'The document will be saved without any password protection.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );

  // ── Execute ──────────────────────────────────────────────────────────

  void _executeAction(PdfSecurityNotifier notifier, PdfSecurityState state) {
    if (state.mode == SecurityMode.protect) {
      notifier.protectPdf(
        userPassword: _userPasswordController.text,
        ownerPassword: _ownerPasswordController.text.isNotEmpty
            ? _ownerPasswordController.text
            : null,
      );
    } else {
      notifier.unlockPdf(password: _unlockPasswordController.text);
    }
  }
}

// ── Reusable Widgets ─────────────────────────────────────────────────────

class _FileInfoTile extends StatelessWidget {
  const _FileInfoTile({required this.state});

  final PdfSecurityState state;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppTheme.spacingMD),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      border: Border.all(color: AppColors.surfaceBorder),
    ),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.electricPurple.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: const Icon(
            Icons.picture_as_pdf_rounded,
            color: AppColors.electricPurple,
          ),
        ),
        const SizedBox(width: AppTheme.spacingSM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                state.originalFileName ?? 'Unknown',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(color: AppColors.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                state.formatBytes(state.originalSize),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.selected, required this.onChanged});

  final SecurityMode selected;
  final ValueChanged<SecurityMode> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: SecurityMode.values.map((mode) {
      final isSelected = mode == selected;
      return Expanded(
        child: Padding(
          padding: EdgeInsets.only(
            right: mode != SecurityMode.values.last ? 8 : 0,
          ),
          child: GestureDetector(
            onTap: () => onChanged(mode),
            child: AnimatedContainer(
              duration: AppTheme.animFast,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.electricPurple.withValues(alpha: 0.15)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(
                  color: isSelected
                      ? AppColors.electricPurple
                      : AppColors.surfaceBorder,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    mode == SecurityMode.protect
                        ? Icons.lock_rounded
                        : Icons.lock_open_rounded,
                    size: 22,
                    color: isSelected
                        ? AppColors.electricPurple
                        : AppColors.textTertiary,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    mode.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isSelected
                          ? AppColors.electricPurple
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList(),
  );
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggle,
  });

  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    obscureText: obscure,
    style: const TextStyle(color: AppColors.textPrimary),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textTertiary),
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        borderSide: const BorderSide(color: AppColors.surfaceBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        borderSide: const BorderSide(color: AppColors.surfaceBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        borderSide: const BorderSide(color: AppColors.electricPurple),
      ),
      suffixIcon: IconButton(
        icon: Icon(
          obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
          color: AppColors.textTertiary,
          size: 20,
        ),
        onPressed: onToggle,
      ),
    ),
  );
}

class _PermissionToggle extends StatelessWidget {
  const _PermissionToggle({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(
      horizontal: AppTheme.spacingMD,
      vertical: 4,
    ),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      border: Border.all(color: AppColors.surfaceBorder),
    ),
    child: Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: AppTheme.spacingSM),
        Expanded(
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.electricPurple,
        ),
      ],
    ),
  );
}
