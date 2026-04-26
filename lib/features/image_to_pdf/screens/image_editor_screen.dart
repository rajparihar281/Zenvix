import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import 'package:zenvix/core/constants/app_strings.dart';
import 'package:zenvix/core/theme/app_colors.dart';
import 'package:zenvix/core/theme/app_theme.dart';
import 'package:zenvix/features/image_to_pdf/models/editable_image.dart';
import 'package:zenvix/features/image_to_pdf/providers/image_to_pdf_provider.dart';

/// Per-image editor with rotate, flip, brightness, contrast, grayscale.
class ImageEditorScreen extends ConsumerStatefulWidget {
  const ImageEditorScreen({super.key, required this.imageIndex});
  final int imageIndex;

  @override
  ConsumerState<ImageEditorScreen> createState() => _ImageEditorScreenState();
}

class _ImageEditorScreenState extends ConsumerState<ImageEditorScreen> {
  late EditableImage _edited;
  bool _initialized = false;
  Vector3 v3 = Vector3(1, 1, 0);
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final state = ref.read(imageToPdfProvider);
      if (widget.imageIndex < state.images.length) {
        _edited = state.images[widget.imageIndex];
      }
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      title: const Text(AppStrings.editImage),
      leading: IconButton(
        icon: const Icon(Icons.close_rounded, size: 22),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        TextButton(
          onPressed: _resetEdits,
          child: const Text(
            AppStrings.reset,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        TextButton(
          onPressed: _applyEdits,
          child: const Text(
            AppStrings.apply,
            style: TextStyle(
              color: AppColors.neonBlue,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
    body: Column(
      children: [
        // Image preview
        Expanded(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4,
            child: Center(
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..rotateZ(_edited.rotation * 3.14159265 / 180)
                  ..scaleByVector3(Vector3(1, 1, 0)),
                child: ColorFiltered(
                  colorFilter: _edited.grayscale
                      ? const ColorFilter.matrix(<double>[
                          0.2126,
                          0.7152,
                          0.0722,
                          0,
                          0,
                          0.2126,
                          0.7152,
                          0.0722,
                          0,
                          0,
                          0.2126,
                          0.7152,
                          0.0722,
                          0,
                          0,
                          0,
                          0,
                          0,
                          1,
                          0,
                        ])
                      : ColorFilter.mode(Colors.transparent, BlendMode.dst),
                  child: ColorFiltered(
                    colorFilter: ColorFilter.matrix(
                      _buildBrightnessContrastMatrix(),
                    ),
                    child: Image.file(
                      File(_edited.originalPath),
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.broken_image,
                        size: 80,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Edit controls
        DecoratedBox(
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
              children: [
                const SizedBox(height: 12),
                // Button row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _EditButton(
                      icon: Icons.rotate_right_rounded,
                      label: AppStrings.rotate,
                      isActive: _edited.rotation != 0,
                      onTap: () => setState(() {
                        _edited = _edited.copyWith(
                          rotation: (_edited.rotation + 90) % 360,
                        );
                      }),
                    ),
                    _EditButton(
                      icon: Icons.flip_rounded,
                      label: AppStrings.flipH,
                      isActive: _edited.flipHorizontal,
                      onTap: () => setState(() {
                        _edited = _edited.copyWith(
                          flipHorizontal: !_edited.flipHorizontal,
                        );
                      }),
                    ),
                    _EditButton(
                      icon: Icons.flip_rounded,
                      label: AppStrings.flipV,
                      isActive: _edited.flipVertical,
                      rotateIcon: true,
                      onTap: () => setState(() {
                        _edited = _edited.copyWith(
                          flipVertical: !_edited.flipVertical,
                        );
                      }),
                    ),
                    _EditButton(
                      icon: Icons.tonality_rounded,
                      label: AppStrings.grayscale,
                      isActive: _edited.grayscale,
                      onTap: () => setState(() {
                        _edited = _edited.copyWith(
                          grayscale: !_edited.grayscale,
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Brightness slider
                _SliderRow(
                  label: AppStrings.brightness,
                  value: _edited.brightness,
                  onChanged: (v) => setState(() {
                    _edited = _edited.copyWith(brightness: v);
                  }),
                ),
                // Contrast slider
                _SliderRow(
                  label: AppStrings.contrast,
                  value: _edited.contrast,
                  onChanged: (v) => setState(() {
                    _edited = _edited.copyWith(contrast: v);
                  }),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  List<double> _buildBrightnessContrastMatrix() {
    final b = _edited.brightness * 40;
    final c = 1.0 + _edited.contrast;
    final t = (1.0 - c) / 2.0 * 255;
    return <double>[
      c,
      0,
      0,
      0,
      b + t,
      0,
      c,
      0,
      0,
      b + t,
      0,
      0,
      c,
      0,
      b + t,
      0,
      0,
      0,
      1,
      0,
    ];
  }

  void _applyEdits() {
    ref
        .read(imageToPdfProvider.notifier)
        .updateImage(widget.imageIndex, _edited);
    Navigator.pop(context);
  }

  void _resetEdits() {
    setState(() {
      _edited = _edited.resetEdits();
    });
  }
}

class _EditButton extends StatelessWidget {
  const _EditButton({
    required this.icon,
    required this.label,
    this.isActive = false,
    required this.onTap,
    this.rotateIcon = false,
  });
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final bool rotateIcon;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.neonBlue.withValues(alpha: 0.15)
                : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: isActive
                  ? AppColors.neonBlue.withValues(alpha: 0.4)
                  : AppColors.surfaceBorder,
            ),
          ),
          child: Transform.rotate(
            angle: rotateIcon ? 1.5708 : 0,
            child: Icon(
              icon,
              size: 22,
              color: isActive ? AppColors.neonBlue : AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? AppColors.neonBlue : AppColors.textTertiary,
          ),
        ),
      ],
    ),
  );
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Slider(value: value, min: -1, onChanged: onChanged),
        ),
        SizedBox(
          width: 36,
          child: Text(
            '${(value * 100).round()}',
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
          ),
        ),
      ],
    ),
  );
}
