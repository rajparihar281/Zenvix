import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:zenvix/core/services/incoming_file_service.dart';
import 'package:zenvix/core/theme/app_colors.dart';
import 'package:zenvix/core/theme/app_theme.dart';

/// Preview / info screen for document types that Zenvix cannot render
/// natively (Word, PowerPoint, Excel).
///
/// Shows file metadata, an animated icon, and a prominent "Open with…"
/// button that delegates to the system's default handler.
class DocumentPreviewScreen extends StatelessWidget {
  const DocumentPreviewScreen({
    super.key,
    required this.filePath,
  });

  /// Absolute path to the document file.
  final String filePath;

  String get _fileName => p.basename(filePath);
  String get _extension => p.extension(filePath).toLowerCase();

  String get _mimeTypeForExtension {
    switch (_extension) {
      case '.doc': return 'application/msword';
      case '.docx': return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case '.ppt': return 'application/vnd.ms-powerpoint';
      case '.pptx': return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case '.xls': return 'application/vnd.ms-excel';
      case '.xlsx': return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case '.csv': return 'text/csv';
      default: return 'application/octet-stream';
    }
  }

  // ── File metadata helpers ────────────────────────────────────────────

  _DocMeta get _meta {
    switch (_extension) {
      case '.doc':
      case '.docx':
        return _DocMeta(
          icon: Icons.description_outlined,
          label: 'Word Document',
          color: AppColors.neonBlue,
          category: IncomingFileCategory.document,
        );
      case '.ppt':
      case '.pptx':
        return _DocMeta(
          icon: Icons.slideshow_outlined,
          label: 'PowerPoint Presentation',
          color: AppColors.accentPink,
          category: IncomingFileCategory.presentation,
        );
      case '.xls':
      case '.xlsx':
        return _DocMeta(
          icon: Icons.table_chart_outlined,
          label: 'Excel Spreadsheet',
          color: AppColors.success,
          category: IncomingFileCategory.spreadsheet,
        );
      case '.csv':
        return _DocMeta(
          icon: Icons.grid_on_rounded,
          label: 'CSV Spreadsheet',
          color: AppColors.success,
          category: IncomingFileCategory.spreadsheet,
        );
      default:
        return _DocMeta(
          icon: Icons.insert_drive_file_outlined,
          label: 'Document',
          color: AppColors.textSecondary,
          category: IncomingFileCategory.unsupported,
        );
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // ── Actions ──────────────────────────────────────────────────────────

  static const _channel = MethodChannel('com.Zenvix.Zenvix/incoming_file');

  Future<void> _openWithSystem(BuildContext context) async {
    try {
      // Get a FileProvider content:// URI from native — file:// URIs are
      // blocked by StrictMode on Android 7+ (FileUriExposedException).
      final contentUri = await _channel.invokeMethod<String>(
        'getContentUri',
        filePath,
      );
      if (contentUri == null || contentUri.isEmpty) {
        throw PlatformException(code: 'URI_FAILED', message: 'No URI returned');
      }
      // Ask native to launch the VIEW intent with the content URI and
      // FLAG_GRANT_READ_URI_PERMISSION so the receiving app can read it.
      await _channel.invokeMethod<void>('openFile', {
        'uri': contentUri,
        'mimeType': _mimeTypeForExtension,
      });
    } on PlatformException catch (e) {
      debugPrint('[DocumentPreview] Open failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open: ${e.message}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _share() async {
    await Share.shareXFiles(
      [XFile(filePath)],
      text: 'Shared from Zenvix',
    );
  }

  @override
  Widget build(BuildContext context) {
    final meta = _meta;
    final file = File(filePath);
    final fileSize =
        file.existsSync() ? _formatBytes(file.lengthSync()) : 'Unknown';
    final lastModified = file.existsSync()
        ? file.lastModifiedSync().toLocal().toString().split('.').first
        : 'Unknown';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(
          _fileName,
          style: const TextStyle(fontSize: 15),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, size: 22),
            tooltip: 'Share',
            onPressed: _share,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingXL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Animated icon ──────────────────────────────────────
              _AnimatedDocIcon(
                icon: meta.icon,
                color: meta.color,
              ),
              const SizedBox(height: AppTheme.spacingLG),

              // ── File type badge ────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: meta.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: meta.color.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  meta.label,
                  style: TextStyle(
                    color: meta.color,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingLG),

              // ── File name ──────────────────────────────────────────
              Text(
                _fileName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppTheme.spacingXL),

              // ── Metadata cards ─────────────────────────────────────
              _MetadataRow(label: 'Size', value: fileSize),
              const SizedBox(height: 8),
              _MetadataRow(label: 'Extension', value: _extension),
              const SizedBox(height: 8),
              _MetadataRow(label: 'Last Modified', value: lastModified),
              SizedBox(height: AppTheme.spacingXL * 1.5),

              // ── Open with system button ────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => _openWithSystem(context),
                  icon: const Icon(Icons.open_in_new_rounded, size: 20),
                  label: const Text(
                    'Open with…',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: meta.color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Share button ───────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _share,
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: const Text('Share File'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.surfaceBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppTheme.spacingLG),

              // ── Info note ──────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: AppColors.info.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'This file type requires an external app to view. '
                        'Tap "Open with…" to choose an app.',
                        style: TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Private helper widgets ─────────────────────────────────────────────

class _AnimatedDocIcon extends StatefulWidget {
  const _AnimatedDocIcon({
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;

  @override
  State<_AnimatedDocIcon> createState() => _AnimatedDocIconState();
}

class _AnimatedDocIconState extends State<_AnimatedDocIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scale = Tween<double>(begin: 1, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _glow = Tween<double>(begin: 0.15, end: 0.35).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (_, unused) => Transform.scale(
          scale: _scale.value,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color.withValues(alpha: 0.1),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: _glow.value),
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: Icon(
              widget.icon,
              size: 48,
              color: widget.color,
            ),
          ),
        ),
      );
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            Flexible(
              child: Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
}

/// Internal metadata holder for document types.
class _DocMeta {
  const _DocMeta({
    required this.icon,
    required this.label,
    required this.color,
    required this.category,
  });

  final IconData icon;
  final String label;
  final Color color;
  final IncomingFileCategory category;
}
