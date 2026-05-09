import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zenvix/core/theme/app_colors.dart';
import 'package:zenvix/core/theme/app_theme.dart';
import 'package:zenvix/features/pdf_watermark/application/providers/pdf_watermark_provider.dart';
import 'package:zenvix/features/pdf_watermark/domain/models/watermark_options.dart';
import 'package:zenvix/features/pdf_watermark/presentation/screens/pdf_watermark_result_screen.dart';
import 'package:zenvix/shared/widgets/error_snackbar.dart';
import 'package:zenvix/shared/widgets/neon_button.dart';

class PdfWatermarkScreen extends ConsumerWidget {
  const PdfWatermarkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pdfWatermarkProvider);
    final notifier = ref.read(pdfWatermarkProvider.notifier);

    ref.listen<PdfWatermarkState>(pdfWatermarkProvider, (prev, next) {
      if (next.errorMessage != null &&
          prev?.errorMessage != next.errorMessage) {
        showErrorSnackbar(context, message: next.errorMessage!);
        notifier.clearError();
      }
      if (next.status == WatermarkStatus.done &&
          next.watermarkedData != null &&
          prev?.status != WatermarkStatus.done) {
        Navigator.push(
          context,
          MaterialPageRoute<PdfWatermarkResultScreen>(
            builder: (_) => const PdfWatermarkResultScreen(),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('PDF Watermark'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            notifier.reset();
            Navigator.pop(context);
          },
        ),
      ),
      body: state.pdfData == null
          ? _EmptyState(notifier: notifier, state: state)
          : _ConfigView(state: state, notifier: notifier),
    );
  }
}

// ── Empty State ──────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.notifier, required this.state});

  final PdfWatermarkNotifier notifier;
  final PdfWatermarkState state;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accentCyan.withValues(alpha: 0.1),
          ),
          child: const Icon(
            Icons.branding_watermark_rounded,
            size: 48,
            color: AppColors.accentCyan,
          ),
        ),
        const SizedBox(height: AppTheme.spacingLG),
        Text(
          'Add Watermark to PDF',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.spacingSM),
        Text(
          'Text or image watermark on every page',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.spacingXL),
        NeonButton(
          label: 'Select PDF',
          icon: Icons.upload_file_rounded,
          expanded: false,
          isLoading: state.status == WatermarkStatus.loading,
          onPressed: notifier.pickPdf,
        ),
      ],
    ),
  );
}

// ── Config View ──────────────────────────────────────────────────────────

class _ConfigView extends ConsumerWidget {
  const _ConfigView({required this.state, required this.notifier});

  final PdfWatermarkState state;
  final PdfWatermarkNotifier notifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    children: [
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FileInfoCard(state: state),
              const SizedBox(height: AppTheme.spacingMD),
              _WatermarkTypeToggle(state: state, notifier: notifier),
              const SizedBox(height: AppTheme.spacingMD),
              _WatermarkPreview(options: state.options),
              const SizedBox(height: AppTheme.spacingMD),
              if (state.options.type == WatermarkType.text)
                _TextControls(state: state, notifier: notifier)
              else
                _ImageControls(state: state, notifier: notifier),
              const SizedBox(height: AppTheme.spacingMD),
              _CommonControls(state: state, notifier: notifier),
            ],
          ),
        ),
      ),
      _BottomBar(state: state, notifier: notifier),
    ],
  );
}

// ── File Info Card ───────────────────────────────────────────────────────

class _FileInfoCard extends StatelessWidget {
  const _FileInfoCard({required this.state});

  final PdfWatermarkState state;

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
            color: AppColors.accentCyan.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: const Icon(
            Icons.picture_as_pdf_rounded,
            color: AppColors.accentCyan,
          ),
        ),
        const SizedBox(width: AppTheme.spacingSM),
        Expanded(
          child: Text(
            state.originalFileName ?? 'Unknown',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(color: AppColors.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

// ── Type Toggle ──────────────────────────────────────────────────────────

class _WatermarkTypeToggle extends StatelessWidget {
  const _WatermarkTypeToggle({required this.state, required this.notifier});

  final PdfWatermarkState state;
  final PdfWatermarkNotifier notifier;

  @override
  Widget build(BuildContext context) => Row(
    children: WatermarkType.values.map((type) {
      final isSelected = state.options.type == type;
      final label = type == WatermarkType.text ? 'Text' : 'Image';
      final icon = type == WatermarkType.text
          ? Icons.text_fields_rounded
          : Icons.image_rounded;
      return Expanded(
        child: Padding(
          padding: EdgeInsets.only(
            right: type == WatermarkType.text ? AppTheme.spacingSM : 0,
          ),
          child: GestureDetector(
            onTap: () => notifier.updateOptions(
              state.options.copyWith(type: type),
            ),
            child: AnimatedContainer(
              duration: AppTheme.animFast,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accentCyan.withValues(alpha: 0.12)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(
                  color: isSelected
                      ? AppColors.accentCyan
                      : AppColors.surfaceBorder,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: isSelected
                        ? AppColors.accentCyan
                        : AppColors.textTertiary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isSelected
                          ? AppColors.accentCyan
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

// ── Watermark Preview ────────────────────────────────────────────────────

class _WatermarkPreview extends StatelessWidget {
  const _WatermarkPreview({required this.options});

  final WatermarkOptions options;

  @override
  Widget build(BuildContext context) => Container(
    height: 180,
    decoration: BoxDecoration(
      color: AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      border: Border.all(color: AppColors.surfaceBorder),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      child: Stack(
        children: [
          // Page background
          Container(color: Colors.white.withValues(alpha: 0.05)),
          // Watermark overlay
          Positioned.fill(
            child: CustomPaint(
              painter: _WatermarkPainter(options: options),
            ),
          ),
          // Label
          Positioned(
            bottom: 8,
            right: 12,
            child: Text(
              'Preview',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textTertiary.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _WatermarkPainter extends CustomPainter {
  const _WatermarkPainter({required this.options});

  final WatermarkOptions options;

  @override
  void paint(Canvas canvas, Size size) {
    if (options.type == WatermarkType.text) {
      _paintText(canvas, size);
    }
    // Image preview shows placeholder since we can't easily decode async here.
  }

  void _paintText(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: options.text.isEmpty ? 'WATERMARK' : options.text,
        style: TextStyle(
          fontSize: options.fontSize * 0.35,
          fontWeight: FontWeight.bold,
          color: options.color.withValues(alpha: options.opacity),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final offset = _resolveOffset(size, textPainter.width, textPainter.height);

    canvas..save()
    ..translate(
      offset.dx + textPainter.width / 2,
      offset.dy + textPainter.height / 2,
    )
    ..rotate(options.rotation * 3.14159 / 180);
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height / 2),
    );
    canvas.restore();
  }

  Offset _resolveOffset(Size size, double w, double h) {
    const margin = 12.0;
    return switch (options.position) {
      WatermarkPosition.center => Offset((size.width - w) / 2, (size.height - h) / 2),
      WatermarkPosition.topLeft => const Offset(margin, margin),
      WatermarkPosition.topRight => Offset(size.width - w - margin, margin),
      WatermarkPosition.bottomLeft => Offset(margin, size.height - h - margin),
      WatermarkPosition.bottomRight =>
        Offset(size.width - w - margin, size.height - h - margin),
    };
  }

  @override
  bool shouldRepaint(_WatermarkPainter oldDelegate) =>
      oldDelegate.options != options;
}

// ── Text Controls ────────────────────────────────────────────────────────

class _TextControls extends StatefulWidget {
  const _TextControls({required this.state, required this.notifier});

  final PdfWatermarkState state;
  final PdfWatermarkNotifier notifier;

  @override
  State<_TextControls> createState() => _TextControlsState();
}

class _TextControlsState extends State<_TextControls> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.state.options.text);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _ControlCard(
    title: 'Text Settings',
    children: [
      TextField(
        controller: _textController,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: const InputDecoration(
          labelText: 'Watermark Text',
          labelStyle: TextStyle(color: AppColors.textSecondary),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.surfaceBorder),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.accentCyan),
          ),
        ),
        onChanged: (v) => widget.notifier.updateOptions(
          widget.state.options.copyWith(text: v),
        ),
      ),
      const SizedBox(height: AppTheme.spacingMD),
      _SliderRow(
        label: 'Font Size',
        value: widget.state.options.fontSize,
        min: 12,
        max: 120,
        displayValue: widget.state.options.fontSize.round().toString(),
        onChanged: (v) => widget.notifier.updateOptions(
          widget.state.options.copyWith(fontSize: v),
        ),
      ),
      const SizedBox(height: AppTheme.spacingSM),
      _ColorRow(
        selected: widget.state.options.color,
        onChanged: (c) => widget.notifier.updateOptions(
          widget.state.options.copyWith(color: c),
        ),
      ),
    ],
  );
}

// ── Image Controls ───────────────────────────────────────────────────────

class _ImageControls extends StatelessWidget {
  const _ImageControls({required this.state, required this.notifier});

  final PdfWatermarkState state;
  final PdfWatermarkNotifier notifier;

  @override
  Widget build(BuildContext context) => _ControlCard(
    title: 'Image Settings',
    children: [
      OutlinedButton.icon(
        onPressed: notifier.pickWatermarkImage,
        icon: const Icon(Icons.image_rounded, size: 18),
        label: Text(
          state.options.imagePath != null ? 'Change Image' : 'Select Image',
        ),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 44),
        ),
      ),
      if (state.options.imagePath != null) ...[
        const SizedBox(height: AppTheme.spacingSM),
        Text(
          state.options.imagePath!.split('/').last.split(r'\').last,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
      const SizedBox(height: AppTheme.spacingMD),
      _SliderRow(
        label: 'Scale',
        value: state.options.imageScale,
        min: 0.05,
        max: 1,
        displayValue: '${(state.options.imageScale * 100).round()}%',
        onChanged: (v) => notifier.updateOptions(
          state.options.copyWith(imageScale: v),
        ),
      ),
    ],
  );
}

// ── Common Controls ──────────────────────────────────────────────────────

class _CommonControls extends StatelessWidget {
  const _CommonControls({required this.state, required this.notifier});

  final PdfWatermarkState state;
  final PdfWatermarkNotifier notifier;

  @override
  Widget build(BuildContext context) => _ControlCard(
    title: 'Placement',
    children: [
      _SliderRow(
        label: 'Opacity',
        value: state.options.opacity,
        min: 0.05,
        max: 1,
        displayValue: '${(state.options.opacity * 100).round()}%',
        onChanged: (v) => notifier.updateOptions(
          state.options.copyWith(opacity: v),
        ),
      ),
      const SizedBox(height: AppTheme.spacingSM),
      _SliderRow(
        label: 'Rotation',
        value: state.options.rotation,
        min: -180,
        max: 180,
        displayValue: '${state.options.rotation.round()}°',
        onChanged: (v) => notifier.updateOptions(
          state.options.copyWith(rotation: v),
        ),
      ),
      const SizedBox(height: AppTheme.spacingMD),
      Text(
        'Position',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: AppTheme.spacingSM),
      _PositionGrid(
        selected: state.options.position,
        onChanged: (p) => notifier.updateOptions(
          state.options.copyWith(position: p),
        ),
      ),
    ],
  );
}

// ── Position Grid ────────────────────────────────────────────────────────

class _PositionGrid extends StatelessWidget {
  const _PositionGrid({required this.selected, required this.onChanged});

  final WatermarkPosition selected;
  final ValueChanged<WatermarkPosition> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppTheme.spacingSM,
    runSpacing: AppTheme.spacingSM,
    children: WatermarkPosition.values.map((pos) {
      final isSelected = pos == selected;
      return GestureDetector(
        onTap: () => onChanged(pos),
        child: AnimatedContainer(
          duration: AppTheme.animFast,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.accentCyan.withValues(alpha: 0.12)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            border: Border.all(
              color: isSelected
                  ? AppColors.accentCyan
                  : AppColors.surfaceBorder,
            ),
          ),
          child: Text(
            pos.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected
                  ? AppColors.accentCyan
                  : AppColors.textSecondary,
            ),
          ),
        ),
      );
    }).toList(),
  );
}

// ── Slider Row ───────────────────────────────────────────────────────────

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.displayValue,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final String displayValue;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(
            displayValue,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.accentCyan,
            ),
          ),
        ],
      ),
      Slider(
        value: value.clamp(min, max),
        min: min,
        max: max,
        onChanged: onChanged,
      ),
    ],
  );
}

// ── Color Row ────────────────────────────────────────────────────────────

class _ColorRow extends StatelessWidget {
  const _ColorRow({required this.selected, required this.onChanged});

  final Color selected;
  final ValueChanged<Color> onChanged;

  static const List<Color> _palette = [
    Colors.white,
    Colors.black,
    Color(0xFFFF1744),
    Color(0xFF00B4FF),
    Color(0xFF9D4EDD),
    Color(0xFF00E676),
    Color(0xFFFFAB00),
    Color(0xFFFF006E),
  ];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Color', style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: AppTheme.spacingSM),
      Wrap(
        spacing: AppTheme.spacingSM,
        children: _palette.map((color) {
          final isSelected = selected.toARGB32()  == color.toARGB32();
          return GestureDetector(
            onTap: () => onChanged(color),
            child: AnimatedContainer(
              duration: AppTheme.animFast,
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
            ),
          );
        }).toList(),
      ),
    ],
  );
}

// ── Control Card ─────────────────────────────────────────────────────────

class _ControlCard extends StatelessWidget {
  const _ControlCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppTheme.spacingMD),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      border: Border.all(color: AppColors.surfaceBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppTheme.spacingMD),
        ...children,
      ],
    ),
  );
}

// ── Bottom Bar ───────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.state, required this.notifier});

  final PdfWatermarkState state;
  final PdfWatermarkNotifier notifier;

  @override
  Widget build(BuildContext context) => SafeArea(
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
              label: 'Apply',
              icon: Icons.branding_watermark_rounded,
              isLoading: state.status == WatermarkStatus.processing,
              onPressed: notifier.applyWatermark,
            ),
          ),
        ],
      ),
    ),
  );
}
