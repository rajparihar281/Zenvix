import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zenvix/core/theme/app_colors.dart';
import 'package:zenvix/core/theme/app_theme.dart';
import 'package:zenvix/features/qr_tools/application/providers/qr_scanner_provider.dart';
import 'package:zenvix/features/qr_tools/domain/models/qr_result.dart';
import 'package:zenvix/features/qr_tools/presentation/widgets/scan_overlay.dart';
import 'package:zenvix/shared/widgets/error_snackbar.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  late final MobileScannerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(qrScannerProvider.notifier).startScanning();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    ref.read(qrScannerProvider.notifier).reset();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final barcode = capture.barcodes.firstOrNull;
    final raw = barcode?.rawValue;
    if (raw == null || raw.isEmpty) {
      return;
    }
    _controller.stop();
    ref.read(qrScannerProvider.notifier).onDetected(raw);
  }

  Future<void> _showResultSheet(QrResult result) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXL),
        ),
      ),
      builder: (ctx) => _ResultSheet(result: result, onScanAgain: _resumeScan),
    );
  }

  void _resumeScan() {
    ref.read(qrScannerProvider.notifier).resumeScanning();
    _controller.start();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(qrScannerProvider);
    final notifier = ref.read(qrScannerProvider.notifier);

    ref.listen<QrScannerState>(qrScannerProvider, (prev, next) {
      if (next.errorMessage != null &&
          prev?.errorMessage != next.errorMessage) {
        showErrorSnackbar(context, message: next.errorMessage!);
        notifier.clearError();
      }
      if (next.status == ScannerStatus.paused && next.result != null) {
        _showResultSheet(next.result!);
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('QR Scanner'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: ValueListenableBuilder<MobileScannerState>(
              valueListenable: _controller,
              builder: (_, scannerState, _) => Icon(
                scannerState.torchState == TorchState.on
                    ? Icons.flash_on_rounded
                    : Icons.flash_off_rounded,
                color: scannerState.torchState == TorchState.on
                    ? AppColors.warning
                    : AppColors.textSecondary,
              ),
            ),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: state.status == ScannerStatus.permissionDenied
          ? _PermissionDeniedView(onRetry: _resumeScan)
          : Stack(
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: _onDetect,
                  errorBuilder: (context, error) => _CameraErrorView(
                    error: error.errorCode.name,
                    onRetry: _resumeScan,
                  ),
                ),
                const ScanOverlay(),
                Positioned(
                  bottom: 48,
                  left: 0,
                  right: 0,
                  child: Text(
                    'Point camera at a QR code',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// ── Result Bottom Sheet ──────────────────────────────────────────────────

class _ResultSheet extends StatelessWidget {
  const _ResultSheet({required this.result, required this.onScanAgain});

  final QrResult result;
  final VoidCallback onScanAgain;

  IconData get _typeIcon {
    switch (result.type) {
      case QrContentType.url:
        return Icons.link_rounded;
      case QrContentType.email:
        return Icons.email_outlined;
      case QrContentType.phone:
        return Icons.phone_outlined;
      case QrContentType.text:
        return Icons.text_fields_rounded;
    }
  }

  Color get _typeColor {
    switch (result.type) {
      case QrContentType.url:
        return AppColors.neonBlue;
      case QrContentType.email:
        return AppColors.electricPurple;
      case QrContentType.phone:
        return AppColors.success;
      case QrContentType.text:
        return AppColors.accentCyan;
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingLG,
        AppTheme.spacingSM,
        AppTheme.spacingLG,
        AppTheme.spacingLG,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _typeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusRound),
                  border: Border.all(color: _typeColor.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_typeIcon, size: 14, color: _typeColor),
                    const SizedBox(width: 4),
                    Text(
                      result.typeLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _typeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMD),

          // Content
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.spacingMD),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: SelectableText(
              result.displayValue,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingLG),

          // Actions
          Row(
            children: [
              _ActionButton(
                icon: Icons.copy_rounded,
                label: 'Copy',
                onTap: () {
                  Clipboard.setData(ClipboardData(text: result.displayValue));
                  Navigator.pop(context);
                  showSuccessSnackbar(context, message: 'Copied to clipboard');
                },
              ),
              const SizedBox(width: AppTheme.spacingSM),
              _ActionButton(
                icon: Icons.share_rounded,
                label: 'Share',
                onTap: () async {
                  Navigator.pop(context);
                  await Share.share(result.displayValue);
                },
              ),
              if (result.type == QrContentType.url) ...[
                const SizedBox(width: AppTheme.spacingSM),
                _ActionButton(
                  icon: Icons.open_in_browser_rounded,
                  label: 'Open',
                  color: AppColors.neonBlue,
                  onTap: () async {
                    final uri = Uri.tryParse(result.rawValue);

                    if (uri != null && await canLaunchUrl(uri)) {
                      if (context.mounted) {
                        Navigator.pop(context);
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    }
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: AppTheme.spacingSM),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                onScanAgain();
              },
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
              label: const Text('Scan Again'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.textSecondary,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.4)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    ),
  );
}

// ── Error / Permission Views ─────────────────────────────────────────────

class _PermissionDeniedView extends StatelessWidget {
  const _PermissionDeniedView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppTheme.spacingXL),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.no_photography_rounded,
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: AppTheme.spacingLG),
          const Text(
            'Camera Access Required',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSM),
          const Text(
            'Please grant camera permission in your device Settings to scan QR codes.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: AppTheme.spacingXL),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Try Again'),
          ),
        ],
      ),
    ),
  );
}

class _CameraErrorView extends StatelessWidget {
  const _CameraErrorView({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, size: 48, color: AppColors.error),
        const SizedBox(height: AppTheme.spacingMD),
        Text(
          'Camera error: $error',
          style: const TextStyle(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.spacingLG),
        OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}
