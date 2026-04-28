import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:zenvix/core/theme/app_colors.dart';
import 'package:zenvix/core/theme/app_theme.dart';
import 'package:zenvix/features/qr_tools/application/providers/qr_generator_provider.dart';
import 'package:zenvix/shared/widgets/error_snackbar.dart';
import 'package:zenvix/shared/widgets/neon_button.dart';

class QrGeneratorScreen extends ConsumerStatefulWidget {
  const QrGeneratorScreen({super.key});

  @override
  ConsumerState<QrGeneratorScreen> createState() => _QrGeneratorScreenState();
}

class _QrGeneratorScreenState extends ConsumerState<QrGeneratorScreen> {
  final _inputController = TextEditingController();
  final _repaintKey = GlobalKey();

  @override
  void dispose() {
    _inputController.dispose();
    ref.read(qrGeneratorProvider.notifier).reset();
    super.dispose();
  }

  Future<void> _generate() async {
    // Small delay so the QR widget has time to render before capture.
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!mounted) {
      return;
    }
    await ref.read(qrGeneratorProvider.notifier).generate(_repaintKey);
  }

  Future<void> _shareQr(Uint8List bytes) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/zenvix_qr.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Generated with Zenvix');
    } on Exception catch (e) {
      if (mounted) {
        showErrorSnackbar(context, message: 'Share failed: $e');
      }
    }
  }

  Future<void> _saveQr(Uint8List bytes) async {
    try {
      Directory? dir;
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download');
        if (!dir.existsSync()) {
          dir = await getExternalStorageDirectory();
        }
      } else {
        dir = await getApplicationDocumentsDirectory();
      }
      if (dir == null) {
        throw Exception('Could not find save directory.');
      }
      final path =
          '${dir.path}/Zenvix_QR_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(path).writeAsBytes(bytes);
      if (mounted) {
        showSuccessSnackbar(context, message: 'Saved to: $path');
      }
    } on Exception catch (e) {
      if (mounted) {
        showErrorSnackbar(context, message: 'Save failed: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(qrGeneratorProvider);
    final notifier = ref.read(qrGeneratorProvider.notifier);

    ref.listen<QrGeneratorState>(qrGeneratorProvider, (prev, next) {
      if (next.errorMessage != null && prev?.errorMessage != next.errorMessage) {
        showErrorSnackbar(context, message: next.errorMessage!);
        notifier.clearError();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('QR Generator'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            notifier.reset();
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── QR Preview ──
            _QrPreview(
              repaintKey: _repaintKey,
              state: state,
            ),
            const SizedBox(height: AppTheme.spacingLG),

            // ── Input ──
            Text('Content', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppTheme.spacingSM),
            TextField(
              controller: _inputController,
              style: const TextStyle(color: AppColors.textPrimary),
              maxLines: 3,
              onChanged: notifier.setInput,
              decoration: InputDecoration(
                hintText: 'Enter text, URL, email…',
                hintStyle: const TextStyle(color: AppColors.textTertiary),
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
                  borderSide: const BorderSide(color: AppColors.accentCyan),
                ),
                suffixIcon: _inputController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _inputController.clear();
                          notifier.setInput('');
                        },
                      )
                    : null,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLG),

            // ── Color Customization ──
            Text('Colors', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppTheme.spacingSM),
            _ColorRow(
              fgColor: Color(state.foregroundColor),
              bgColor: Color(state.backgroundColor),
              onFgChanged: notifier.setForegroundColor,
              onBgChanged: notifier.setBackgroundColor,
            ),
            const SizedBox(height: AppTheme.spacingXL),

            // ── Generate Button ──
            NeonButton(
              label: 'Generate QR Code',
              icon: Icons.qr_code_2_rounded,
              isLoading: state.status == GeneratorStatus.generating,
              onPressed: state.canGenerate ? _generate : null,
            ),

            // ── Action Buttons (after generation) ──
            if (state.pngBytes != null) ...[
              const SizedBox(height: AppTheme.spacingSM),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _saveQr(state.pngBytes!),
                      icon: const Icon(Icons.save_alt_rounded, size: 18),
                      label: const Text('Save'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSM),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _shareQr(state.pngBytes!),
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: const Text('Share'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accentCyan,
                        side: const BorderSide(color: AppColors.accentCyan),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── QR Preview ───────────────────────────────────────────────────────────

class _QrPreview extends StatelessWidget {
  const _QrPreview({required this.repaintKey, required this.state});

  final GlobalKey repaintKey;
  final QrGeneratorState state;

  @override
  Widget build(BuildContext context) {
    final hasInput = state.inputText.trim().isNotEmpty;
    return Center(
      child: Container(
        width: 240,
        height: 240,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(
            color: hasInput
                ? AppColors.accentCyan.withValues(alpha: 0.5)
                : AppColors.surfaceBorder,
          ),
          boxShadow: hasInput
              ? [
                  BoxShadow(
                    color: AppColors.accentCyan.withValues(alpha: 0.1),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ]
              : null,
        ),
        child: hasInput
            ? RepaintBoundary(
                key: repaintKey,
                child: QrImageView(
                  data: state.inputText,
                  size: 240,
                  eyeStyle: QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(state.foregroundColor),
                  ),
                  dataModuleStyle: QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(state.foregroundColor),
                  ),
                  backgroundColor: Color(state.backgroundColor),
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                ),
              )
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.qr_code_2_rounded,
                    size: 64,
                    color: AppColors.textTertiary,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Preview',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Color Row ────────────────────────────────────────────────────────────

class _ColorRow extends StatelessWidget {
  const _ColorRow({
    required this.fgColor,
    required this.bgColor,
    required this.onFgChanged,
    required this.onBgChanged,
  });

  final Color fgColor;
  final Color bgColor;
  final ValueChanged<Color> onFgChanged;
  final ValueChanged<Color> onBgChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _ColorPickerRow(
        label: 'QR Color',
        selected: fgColor,
        onChanged: onFgChanged,
      ),
      const SizedBox(height: AppTheme.spacingSM),
      _ColorPickerRow(
        label: 'Background',
        selected: bgColor,
        onChanged: onBgChanged,
      ),
    ],
  );
}

class _ColorPickerRow extends StatelessWidget {
  const _ColorPickerRow({
    required this.label,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final Color selected;
  final ValueChanged<Color> onChanged;

  static const _presets = <Color>[
    Colors.white,
    Colors.black,
    AppColors.neonBlue,
    AppColors.electricPurple,
    AppColors.accentCyan,
    AppColors.accentPink,
    AppColors.success,
    AppColors.warning,
  ];

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(
        width: 90,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ),
      Expanded(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _presets.map((color) {
              final isSelected = selected.toARGB32() == color.toARGB32();
              return GestureDetector(
                onTap: () => onChanged(color),
                child: AnimatedContainer(
                  duration: AppTheme.animFast,
                  margin: const EdgeInsets.only(right: 8),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.accentCyan
                          : AppColors.surfaceBorder,
                      width: isSelected ? 2.5 : 1,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: color == Colors.white
                              ? Colors.black
                              : Colors.white,
                        )
                      : null,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    ],
  );
}
