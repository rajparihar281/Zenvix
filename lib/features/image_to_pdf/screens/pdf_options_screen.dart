import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenvix/core/constants/app_strings.dart';
import 'package:zenvix/core/theme/app_colors.dart';
import 'package:zenvix/core/theme/app_theme.dart';
import 'package:zenvix/features/image_to_pdf/models/pdf_options.dart';
import 'package:zenvix/features/image_to_pdf/providers/image_to_pdf_provider.dart';

/// Bottom sheet for configuring PDF output options.
class PdfOptionsSheet extends ConsumerStatefulWidget {
  const PdfOptionsSheet({super.key});

  @override
  ConsumerState<PdfOptionsSheet> createState() => _PdfOptionsSheetState();
}

class _PdfOptionsSheetState extends ConsumerState<PdfOptionsSheet> {
  late PdfOptions _options;

  @override
  void initState() {
    super.initState();
    _options = ref.read(imageToPdfProvider).pdfOptions;
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            AppStrings.pdfOptions,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),

          // Page size
          _label(AppStrings.pageSize),
          const SizedBox(height: 8),
          _SegmentedSelector<PdfPageSize>(
            values: PdfPageSize.values,
            selected: _options.pageSize,
            labelOf: (v) => v.label,
            onChanged: (v) =>
                setState(() => _options = _options.copyWith(pageSize: v)),
          ),
          const SizedBox(height: 16),

          // Orientation
          _label(AppStrings.orientation),
          const SizedBox(height: 8),
          _SegmentedSelector<PdfOrientation>(
            values: PdfOrientation.values,
            selected: _options.orientation,
            labelOf: (v) => v.label,
            onChanged: (v) =>
                setState(() => _options = _options.copyWith(orientation: v)),
          ),
          const SizedBox(height: 16),

          // Margin
          _label('${AppStrings.margin}: ${_options.marginMm.round()} mm'),
          Slider(
            value: _options.marginMm,
            max: 30,
            divisions: 30,
            onChanged: (v) =>
                setState(() => _options = _options.copyWith(marginMm: v)),
          ),

          // Scaling
          _label(AppStrings.imageScaling),
          const SizedBox(height: 8),
          _SegmentedSelector<ImageScaling>(
            values: ImageScaling.values,
            selected: _options.scaling,
            labelOf: (v) => v.label,
            onChanged: (v) =>
                setState(() => _options = _options.copyWith(scaling: v)),
          ),
          const SizedBox(height: 24),

          // Apply button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ref
                    .read(imageToPdfProvider.notifier)
                    .updatePdfOptions(_options);
                Navigator.pop(context);
              },
              child: const Text('Apply Settings'),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColors.textSecondary,
    ),
  );
}

/// A generic segmented selector with neon accent.
class _SegmentedSelector<T> extends StatelessWidget {
  const _SegmentedSelector({
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
  });
  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: values.map((v) {
      final isSelected = v == selected;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(v),
          child: AnimatedContainer(
            duration: AppTheme.animFast,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.neonBlue.withValues(alpha: 0.15)
                  : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(
                color: isSelected
                    ? AppColors.neonBlue
                    : AppColors.surfaceBorder,
              ),
            ),
            child: Center(
              child: Text(
                labelOf(v),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? AppColors.neonBlue
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      );
    }).toList(),
  );
}
